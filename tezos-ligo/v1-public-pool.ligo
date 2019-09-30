// variant defining pseudo multi-entrypoint actions
type entry_action is
| Deposit
| Withdraw

type finance_storage is record  
  liquidity: tez;    
end

const noOperations: list(operation) = nil;

function depositImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    if amount = 0mtz
      then skip //fail("No tez transferred!");
      else block {
        finance_storage.liquidity := finance_storage.liquidity + amount;       
      }
  } with(noOperations, finance_storage)

function withdrawImp(var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    const withdrawAmount: tez = 100mtz;  
    var operations: list(operation) := nil;

    if withdrawAmount > finance_storage.liquidity
      then skip //fail("No funds to withdraw!")
      else block {
        const receiver: contract(unit) = get_contract(sender);
        const payoutOperation: operation = transaction(unit, withdrawAmount, receiver);
        operations:= list 
          payoutOperation 
        end;       
        finance_storage.liquidity := finance_storage.liquidity - withdrawAmount;              
      }
  } with(operations, finance_storage)

function main(const action: entry_action; var finance_storage: finance_storage): (list(operation) * finance_storage) is
  block {
    skip
  } with case action of
    | Deposit(param) -> depositImp(finance_storage)
    | Withdraw(param) -> withdrawImp(finance_storage)
    end;  
