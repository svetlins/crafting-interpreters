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
    ip() {
      return ip;
    },
    readCode() {
      ip += 1;
      return executable[callable.functionName].code[ip - 1];
    },

    peekCode() {
      return executable[callable.functionName].code[ip];
    },

    readConstant(constantIndex) {
      return executable[callable.functionName].constants[constantIndex];
    },

    getStackSlot(offset) {
      return stack[stackTop + offset];
    },

    setStackSlot(offset, value) {
      stack[stackTop + offset] = value;
    },

    jump() {
      throw "not implemented";
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
    output = "";
    stack = [];
    globals = {};

    callFrame = createCallFrame(executable, stack, TOP_LEVEL_SCRIPT, [], 0);
    callFrames = [callFrame];

    return {
      output,
      stack,
      globals,
      callFrames,
      nextOp: callFrame?.peekCode(),
      terminated: callFrames.length === 0,
    };
  }

  reset();

  return {
    reset,
    tick() {
      callFrame = callFrames[callFrames.length - 1];

      const op = callFrame?.readCode();

      if (callFrame && op) {
        switch (op) {
          case "LOAD-CONSTANT":
            stack.push(callFrame.readConstant(callFrame.readCode()));
            break;
          case "ADD":
            stack.push(stack.pop() + stack.pop());
            break;
          case "MULTIPLY":
            stack.push(stack.pop() * stack.pop());
            break;
          case "PRINT":
            output = output + stack.pop().toString() + "\n";
            break;
          case "NIL":
            stack.push(null);
            break;
          case "RETURN":
            const result = stack.pop();
            callFrames.pop();
            stack = stack.slice(0, callFrame.stackTop - 1);
            stack.push(result);
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
        nextOp: callFrame?.peekCode(),
        terminated: callFrames.length === 0,
      };
    },
  };
}
