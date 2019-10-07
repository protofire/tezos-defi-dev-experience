// variant defining pseudo multi-entrypoint actions
type entry_action is
| Deposit
| Withdraw

type finance_storage is record  
  deposits: map(address, tez);
  liquidity: tez;    
end

const noOperations: list(operation) = nil;

function depositImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    if amount = 0mtz
      then failwith("No tez transferred!");
      else block {
        finance_storage.liquidity := finance_storage.liquidity + amount;   

        //setting the deposit to the sender
        const depositsMap: map(address, tez) = finance_storage.deposits;                
        const senderDeposit: option(tez) = depositsMap[sender];
        case senderDeposit of          
          | Some(a) -> skip //(failwith("You already have a deposit"): int)
          | None -> block {
             depositsMap[sender] := amount;
             finance_storage.deposits := depositsMap;
          }
        end;     
      }
  } with(noOperations, finance_storage)

function withdrawImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {    
    const senderAddress: address = sender;
    //For testing purposes, comment the line above and uncomment next line.
    //const senderAddress: address = ("tz1MZ4GPjAA2gZxKTozJt8Cu5Gvu6WU2ikZ4" : address);

    const senderDeposit: tez = get_force(senderAddress, finance_storage.deposits);
    var operations: list(operation) := nil;    

    if senderDeposit = 0mtz or senderDeposit > finance_storage.liquidity
      then failwith("No funds to withdraw!")
      else block {
        // Create the operation to transfer tez to sender
        const receiver: contract(unit) = get_contract(senderAddress);
        const payoutOperation: operation = transaction(unit, senderDeposit, receiver);
        operations:= list 
          payoutOperation 
        end;  

        // update liquidity pool
        finance_storage.liquidity := finance_storage.liquidity - senderDeposit;              

        // update deposits for sender
        const depositsMap: map(address, tez) = finance_storage.deposits;  
        depositsMap[senderAddress] := 0mtz;
        finance_storage.deposits := depositsMap;              
      }
  } with(operations, finance_storage)

function main(const action: entry_action; var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    skip
  } with case action of
    | Deposit(param) -> depositImp(finance_storage)
    | Withdraw(param) -> withdrawImp(finance_storage)
    end;  
