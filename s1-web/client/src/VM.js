import { loxValueToString, shortLittleEndianToInteger } from "./utils";

const TOP_LEVEL_SCRIPT = {
  functionName: "__toplevel__",
  heapSlots: [],
  heapView: [],
};

function falsey(loxValue) {
  return !loxValue;
}

function equal(firstLoxValue, secondLoxValue) {
  return firstLoxValue === secondLoxValue;
}

function createCallable(functionDescriptor, heapView) {
  return {
    functionName: functionDescriptor.name,
    heapSlots: functionDescriptor.heap_slots,
    arity: functionDescriptor.arity,
    heapView: heapView,
  };
}

function createCallFrame(executable, stack, callable, heapSlots, stackTop) {
  let ip = 0;

  return {
    stackTop,
    functionName: callable.functionName,
    callable,
    heapSlots,
    readCode() {
      ip += 1;
      return executable.functions[callable.functionName][ip - 1];
    },
    ip() {
      return ip;
    },
    readShort() {
      return shortLittleEndianToInteger(this.readCode(), this.readCode());
    },

    peekCode() {
      return executable.functions[callable.functionName][ip];
    },

    readConstant(constantIndex) {
      return executable.constants[constantIndex];
    },

    getStackSlot(offset) {
      return stack[stackTop + offset];
    },

    setStackSlot(offset, value) {
      stack[stackTop + offset] = value;
    },

    jump(offset) {
      ip += offset;
    },
  };
}

export class VM {
  constructor(executable) {
    this.executable = executable;
    this.reset();
  }

  reset() {
    this.output = [];
    this.stack = [];
    this.globals = {};
    this.callFrames = [
      createCallFrame(this.executable, this.stack, TOP_LEVEL_SCRIPT, {}, 0),
    ];
  }

  step() {
    const callFrame = this.callFrames[this.callFrames.length - 1];

    const op = callFrame?.readCode();

    if (callFrame && op) {
      switch (op) {
        case "DEFINE-GLOBAL":
          this.globals[callFrame.readConstant(callFrame.readCode())] =
            this.stack.pop();
          break;
        case "GET-GLOBAL":
          this.stack.push(
            this.globals[callFrame.readConstant(callFrame.readCode())]
          );
          break;
        case "SET-GLOBAL":
          this.globals[callFrame.readConstant(callFrame.readCode())] =
            this.stack.pop();
          break;
        case "GET-LOCAL":
          this.stack.push(callFrame.getStackSlot(callFrame.readCode()));
          break;
        case "SET-LOCAL":
          callFrame.setStackSlot(
            callFrame.readCode(),
            this.stack[this.stack.length - 1]
          );
          break;
        case "INIT-HEAP": {
          const heapSlot = callFrame.readShort();
          callFrame.heapSlots[heapSlot].value = this.stack.pop();
          break;
        }
        case "SET-HEAP": {
          const heapSlot = callFrame.readShort();
          (
            callFrame.callable.heapView[heapSlot] ||
            callFrame.heapSlots[heapSlot]
          ).value = this.stack[this.stack.length - 1];
          break;
        }
        case "GET-HEAP": {
          const heapSlot = callFrame.readShort();
          this.stack.push(
            (
              callFrame.callable.heapView[heapSlot] ||
              callFrame.heapSlots[heapSlot]
            ).value
          );
          break;
        }
        case "EQUAL": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(equal(a, b));
          break;
        }
        case "LESSER": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a < b);
          break;
        }
        case "GREATER": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a > b);
          break;
        }
        case "NOT":
          this.stack.push(!this.stack.pop());
          break;
        case "LOAD-CONSTANT":
          this.stack.push(callFrame.readConstant(callFrame.readCode()));
          break;
        case "LOAD-CLOSURE":
          const functionDescriptor = callFrame.readConstant(
            callFrame.readCode()
          );

          const heapView = Object.fromEntries(
            functionDescriptor.heap_usages.map((heapUsage) => [
              heapUsage,
              callFrame.callable.heapView[heapUsage] ||
                callFrame.heapSlots[heapUsage],
            ])
          );

          const callable = createCallable(functionDescriptor, heapView);
          this.stack.push(callable);
          break;
        case "ADD": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a + b);
          break;
        }
        case "SUBTRACT": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a - b);
          break;
        }
        case "MULTIPLY": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a * b);
          break;
        }
        case "DIVIDE": {
          const b = this.stack.pop();
          const a = this.stack.pop();
          this.stack.push(a / b);
          break;
        }
        case "PRINT":
          this.output.push(loxValueToString(this.stack.pop()));
          break;
        case "POP":
          this.stack.pop();
          break;
        case "NIL":
          this.stack.push(null);
          break;
        case "TRUE":
          this.stack.push(true);
          break;
        case "NEGATE":
          this.stack.push(-this.stack.pop());
          break;
        case "FALSE":
          this.stack.push(false);
          break;
        case "JUMP-ON-FALSE":
          const offset = callFrame.readShort();
          if (falsey(this.stack[this.stack.length - 1])) callFrame.jump(offset);
          break;
        case "JUMP":
          callFrame.jump(callFrame.readShort());
          break;
        case "CALL": {
          const argumentCount = callFrame.readCode();
          const callable = this.stack[this.stack.length - argumentCount - 1];

          const heapSlots = Object.fromEntries(
            callable.heapSlots.map((heapSlot) => [heapSlot, {}])
          );

          const newCallFrame = createCallFrame(
            this.executable,
            this.stack,
            callable,
            heapSlots,
            this.stack.length - argumentCount
          );

          this.callFrames.push(newCallFrame);
          break;
        }
        case "RETURN":
          const result = this.stack.pop();
          this.callFrames.pop();

          while (
            this.stack.length > 0 &&
            this.stack.length >= callFrame.stackTop
          )
            this.stack.pop();

          if (this.callFrames.length > 0) {
            this.stack.push(result);
          }
          break;
        default:
          break;
      }
    }
  }

  currentState() {
    return {
      output: this.output,
      stack: this.stack,
      globals: this.globals,
      callFrames: this.callFrames,
      callFrame: this.callFrames[this.callFrames.length - 1],
      nextOp: this.callFrames[this.callFrames.length - 1]?.peekCode(),
      terminated: this.callFrames.length === 0,
    };
  }

  run() {
    while (this.callFrames.length > 0) {
      this.step();
    }
  }
}
