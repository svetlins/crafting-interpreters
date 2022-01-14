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
    readCode() {
      ip += 1;
      return executable[callable.functionName].code[ip - 1];
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

export function execute(executable) {
  let stack = [];
  const globals = {};

  const callFrames = [createCallFrame(executable, stack, TOP_LEVEL_SCRIPT)];

  do {
    const callFrame = callFrames[callFrames.length - 1];

    const op = callFrame.readCode();

    switch (op) {
      case "LOAD-CONSTANT":
        stack.push(callFrame.readConstant(callFrame.readCode()));
        break;
      case "ADD":
        stack.push(stack.pop() + stack.pop());
        break;
      case "MULTIPLY":
        const b = stack.pop();
        const a = stack.pop();
        stack.push(a * b);
        break;
      case "PRINT":
        console.log("PRINTED:", stack.pop());
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
  } while (callFrames.length > 0);

  console.log("STACK AT END: ", stack);
}
