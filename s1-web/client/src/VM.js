import { shortBigEndianToInteger } from "./utils";

const TOP_LEVEL_SCRIPT = {
  functionName: "__script__",
  heapSlots: [],
  heapView: [],
};

function createCallable(functionDescriptor, heapView) {
  return {
    functionName: functionDescriptor.name,
    heapSlots: functionDescriptor.slots,
    heapView: heapView,
  };
}

function createCallFrame(executable, stack, callable, heapSlots, stackTop) {
  let ip = 0;

  return {
    stackTop,
    functionName: callable.functionName,
    ip() {
      return ip;
    },
    readCode() {
      ip += 1;
      return executable.functions[callable.functionName][ip - 1];
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

    jump(offsetByte1, offsetByte2) {
      const offset = shortBigEndianToInteger(offsetByte1, offsetByte2);
      ip = ip + offset;
    },
  };
}

export function createVM(executable) {
  let output;
  let stack;
  let globals;

  let callFrame;
  let callFrames;

  function reset() {
    output = [];
    stack = [];
    globals = {};

    callFrame = createCallFrame(executable, stack, TOP_LEVEL_SCRIPT, [], 0);
    callFrames = [callFrame];

    return {
      output,
      stack,
      globals,
      callFrames,
      callFrame,
      nextOp: callFrame?.peekCode(),
      terminated: callFrames.length === 0,
    };
  }

  reset();

  return {
    reset,
    step() {
      callFrame = callFrames[callFrames.length - 1];

      const op = callFrame?.readCode();

      if (callFrame && op) {
        switch (op) {
          case "DEFINE-GLOBAL":
            globals[callFrame.readConstant(callFrame.readCode())] = stack.pop();
            break;
          case "GET-GLOBAL":
            stack.push(globals[callFrame.readConstant(callFrame.readCode())]);
            break;
          case "GET-LOCAL":
            stack.push(callFrame.getStackSlot(callFrame.readCode()));
            break;
          case "SET-LOCAL":
            callFrame.setStackSlot(
              callFrame.readCode(),
              stack[stack.length - 1]
            );
            break;
          case "LESSER":
            // eslint-disable-next-line no-self-compare
            stack.push(stack.pop() > stack.pop());
            break;
          case "GREATER":
            // eslint-disable-next-line no-self-compare
            stack.push(stack.pop() < stack.pop());
            break;
          case "NOT":
            stack.push(!stack.pop());
            break;
          case "LOAD-CONSTANT":
            stack.push(callFrame.readConstant(callFrame.readCode()));
            break;
          case "LOAD-CLOSURE":
            const functionDescriptor = callFrame.readConstant(
              callFrame.readCode()
            );
            const callable = createCallable(functionDescriptor, {});
            stack.push(callable);
            break;
          case "ADD":
            const addB = stack.pop();
            const addA = stack.pop();
            stack.push(addA + addB);
            break;
          case "SUBTRACT":
            const b = stack.pop();
            const a = stack.pop();
            stack.push(a - b);
            break;
          case "MULTIPLY":
            stack.push(stack.pop() * stack.pop());
            break;
          case "PRINT":
            output.push(stack.pop().toString());
            break;
          case "POP":
            stack.pop();
            break;
          case "NIL":
            stack.push(null);
            break;
          case "JUMP-ON-FALSE":
            const offsetByte1 = callFrame.readCode();
            const offsetByte2 = callFrame.readCode();
            if (!stack[stack.length - 1])
              callFrame.jump(offsetByte1, offsetByte2);
            break;
          case "JUMP":
            const offsetByte12 = callFrame.readCode();
            const offsetByte22 = callFrame.readCode();
            callFrame.jump(offsetByte12, offsetByte22);
            break;
          case "CALL":
            const argumentCount = callFrame.readCode();
            const callable2 = stack[stack.length - argumentCount - 1];

            const newCallFrame = createCallFrame(
              executable,
              stack,
              callable2,
              [],
              stack.length - argumentCount
            );

            callFrames.push(newCallFrame);
            callFrame = newCallFrame;
            break;
          case "RETURN":
            const result = stack.pop();
            callFrames.pop();
            stack = stack.slice(0, callFrame.stackTop - 1);
            if (callFrames.length > 0) {
              callFrame = callFrames[callFrames.length - 1];
              stack.push(result);
            }
            break;
          default:
            break;
        }
      }

      return {
        output,
        stack,
        globals,
        callFrames,
        callFrame,
        nextOp: callFrame?.peekCode(),
        terminated: callFrames.length === 0,
      };
    },
  };
}
