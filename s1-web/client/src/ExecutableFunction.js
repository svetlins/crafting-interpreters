import { useMemo } from "react";
import { Badge } from "./Badge";
import { shortBigEndianToInteger } from "./utils";

const opcodeSizes = {
  "LOAD-CONSTANT": 2,
  "LOAD-CLOSURE": 2,
  "DEFINE-GLOBAL": 2,
  "SET-GLOBAL": 2,
  "GET-GLOBAL": 2,
  "SET-LOCAL": 2,
  "GET-LOCAL": 2,
  "INIT-HEAP": 3,
  "SET-HEAP": 3,
  "GET-HEAP": 3,
  "JUMP-ON-FALSE": 3,
  CALL: 2,
  JUMP: 3,
};

export function ExecutableFunction({ executable, functionName, highlight }) {
  const code = executable.functions[functionName];
  const constants = executable.constants;

  const ops = useMemo(() => {
    const ops = [];
    for (let i = 0; i < code.length; i++) {
      const opStart = i;
      const opcode = code[i];
      const opcodeSize = opcodeSizes[opcode] || 1;
      let text;

      if (
        opcode === "LOAD-CONSTANT" ||
        opcode === "DEFINE-GLOBAL" ||
        opcode === "SET-GLOBAL" ||
        opcode === "GET-GLOBAL"
      ) {
        const constantIndex = code[i + 1];
        text = `${opcode} ( $${constantIndex} = ${JSON.stringify(
          constants[constantIndex]
        )})`;
      } else if (opcode === "LOAD-CLOSURE") {
        const constantIndex = code[i + 1];
        const functionDescriptor = constants[constantIndex];
        text = `${opcode} ( fun ${functionDescriptor.name}/${functionDescriptor.arity} )`;
      } else if (opcode === "JUMP-ON-FALSE" || opcode === "JUMP") {
        const jumpOffset = shortBigEndianToInteger(code[i + 1], code[i + 2]);
        text = `${opcode} ( target = ${jumpOffset + i + opcodeSize})`;
      } else if (
        opcode === "INIT-HEAP" ||
        opcode === "GET-HEAP" ||
        opcode === "SET-HEAP"
      ) {
        const heapSlot = shortBigEndianToInteger(code[i + 1], code[i + 2]);
        text = `${opcode} ( heapSlot = ${heapSlot})`;
      } else if (opcodeSize > 1) {
        const args = code.slice(i + 1, i + opcodeSize);
        text = `${opcode} ( arg = ${args.join(", ")})`;
      } else {
        text = `${opcode}`;
      }

      i += opcodeSize - 1;

      ops.push([text, opStart]);
    }

    return ops;
  }, [code, constants]);

  return (
    <div className="flex flex-col items-start">
      {ops.map(([op, offset]) => (
        <div className="truncate" key={offset}>
          <span className="text-xs ml-4">{offset}: </span>
          <Badge
            text={op}
            color={offset === highlight ? "red" : "blue"}
            highlight={offset === highlight}
          />
        </div>
      ))}
    </div>
  );
}
