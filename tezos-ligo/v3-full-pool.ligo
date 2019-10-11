// variant defining pseudo multi-entrypoint actions
type entry_action is
| Deposit
| Withdraw

type deposit_info is record
  tezAmount: tez;
  blockTimestamp: timestamp;
end

type finance_storage is record  
  deposits: map(address, deposit_info);
  liquidity: tez;   
end

const noOperations: list(operation) = nil;

function getSender(const mock: bool): address is
  block {
    var senderAddress: address := sender;  
    if mock 
      then senderAddress := ("tz1MZ4GPjAA2gZxKTozJt8Cu5Gvu6WU2ikZ4" : address);
      else skip
  } with(senderAddress)

function calculateInterest(const elapsedBlocks: int): tez is
  block {
    const interest: tez = 0tz;

    if(elapsedBlocks >= 100)
       then interest := 1tz;
       else skip
  } with(interest)

function depositImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    if amount = 0mtz
      then failwith("No tez transferred!");
      else block {     
        const senderAddress: address = getSender(False);

        //setting the deposit to the sender
        var depositsMap: map(address, deposit_info) := finance_storage.deposits;    
        var senderDepositInfo: option(deposit_info) := depositsMap[senderAddress];            

        case senderDepositInfo of          
          | Some(di) -> 
            block {                 
              const elapsedBlocks:int = now - di.blockTimestamp;
              di.tezAmount := di.tezAmount + calculateInterest(elapsedBlocks);
              di.blockTimestamp := now;

              depositsMap[senderAddress] := di;            
              finance_storage.deposits := depositsMap;              
            }
          | None -> 
            block {
              finance_storage.liquidity := finance_storage.liquidity + amount;  

              const deposit : deposit_info = record
                tezAmount = amount;
                blockTimestamp = now;
              end;

              depositsMap[sender] := deposit;
              finance_storage.deposits := depositsMap;
            }
        end;     
      }
  } with(noOperations, finance_storage)

function withdrawImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {    
    const senderAddress: address = getSender(False);

    var operations: list(operation) := nil;
        
    var di: deposit_info := get_force(senderAddress, finance_storage.deposits);
    const elapsedBlocks:int = now - di.blockTimestamp;
    var withdrawAmount: tez := di.tezAmount + calculateInterest(elapsedBlocks);

    if withdrawAmount > finance_storage.liquidity
      then failwith("No tez to withdraw!");
      else block {
        // update storage
        var depositsMap: map(address, deposit_info) := finance_storage.deposits;                
        remove senderAddress from map depositsMap;
        finance_storage.deposits := depositsMap;  

        finance_storage.liquidity := finance_storage.liquidity - withdrawAmount;                              

        // Create the operation to transfer tez to sender
        const receiver: contract(unit) = get_contract(senderAddress);
        const payoutOperation: operation = transaction(unit, withdrawAmount, receiver);
        operations:= list 
           payoutOperation 
        end;          
      }
  } with(operations, finance_storage)

// Entrypoint
function main(const action: entry_action; var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    skip
  } with case action of
    | Deposit(param) -> depositImp(finance_storage)
    | Withdraw(param) -> withdrawImp(finance_storage)
    end;  

//const senderDeposit: tez = case finance_storage.deposits[sender] of | None -> failwith("") | Some x -> x    

// ligo dry-run v3-full-pool.ligo --syntax pascaligo --amount 73 main "Deposit(unit)" "record deposits = (map end: map(address, deposit_info));  liquidity = 0mtz; end"
// ligo dry-run v3-full-pool.ligo --syntax pascaligo --amount 3 main "Deposit(unit)" 'record deposits = map ("tz1MZ4GPjAA2gZxKTozJt8Cu5Gvu6WU2ikZ4" : address) -> record tezAmount = 3000000mtz; blockTimestamp = 1570635360; end; end;  liquidity = 3000000mtz; end'
// ligo dry-run v3-full-pool.ligo --syntax pascaligo --amount 3 main "Withdraw(unit)" 'record deposits = map ("tz1MZ4GPjAA2gZxKTozJt8Cu5Gvu6WU2ikZ4" : address) -> record tezAmount = 4000000mtz; blockTimestamp = 1570635360; end; end;  liquidity = 6000000mtz; end'

// ligo compile-contract v3-full-pool.ligo main | tr -d '\r' > v3-full-pool.tz && docker cp v3-full-pool.tz alphanet_node_1_9cf366d04dd4:/home/tezos

// ligo compile-storage v3-full-pool.ligo main "record deposits = (map end: map(address, deposit_info));  liquidity = 0mtz; end"

// $ alpha-client originate contract v3-full-pool for contractOwner transferring 0 from contractOwner running v3-full-pool.tz  --init "(Pair {} 0)" --burn-cap 4.442 --force^C
// $ alpha-client transfer 3 from bob to v3-full-pool --arg "(Left Unit)" --burn-cap 0.045
// $ alpha-client transfer 1 from bob to v3-full-pool --arg "(Left Unit)" --burn-cap 0.045

// next command will fail, liquidity is lower than bob funds (if elapsedBlocks > 100)
// $ alpha-client transfer 0 from bob to v3-full-pool --arg "(Right Unit)"

// $ alpha-client transfer 10 from contractOwner to v3-full-pool --arg "(Left Unit)" --burn-cap 0.045

// $ alpha-client transfer 0 from bob to v3-full-pool --arg "(Right Unit)"



