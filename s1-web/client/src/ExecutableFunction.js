import { useMemo } from "react";
import { Badge } from "./Badge";
import { shortLittleEndianToInteger } from "./utils";
import classNames from "classnames";

const opcodeSizes = {
  "LOAD-CONSTANT": 2,
  "LOAD-CLOSURE": 2,
  "DEFINE-GLOBAL": 2,
  "SET-GLOBAL": 2,
  "GET-GLOBAL": 2,
  "SET-LOCAL": 2,
  "GET-LOCAL": 2,
  "SET-UPVALUE": 2,
  "GET-UPVALUE": 2,
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
      } else if (opcode === "JUMP-ON-FALSE" || opcode === "JUMP") {
        const jumpOffset = shortLittleEndianToInteger(code[i + 1], code[i + 2]);
        text = `${opcode} ( target = ${jumpOffset + i + opcodeSize})`;
      } else if (
        opcode === "INIT-HEAP" ||
        opcode === "GET-HEAP" ||
        opcode === "SET-HEAP"
      ) {
        const heapSlot = shortLittleEndianToInteger(code[i + 1], code[i + 2]);
        text = `${opcode} ( heapSlot = ${heapSlot})`;
      } else if (opcodeSize > 1) {
        const args = code.slice(i + 1, i + opcodeSize);
        text = `${opcode} ( arg = ${args.join(", ")})`;
      } else {
        text = `${opcode}`;
      }

      if (opcode === "LOAD-CLOSURE") {
        // special case because variable length
        const constantIndex = code[i + 1];
        const functionDescriptor = constants[constantIndex];
        text = `${opcode} ( fun ${functionDescriptor.name}/${functionDescriptor.arity} )`;

        ops.push([text, opStart]);
        for (
          let upvalueIndex = 0;
          upvalueIndex < functionDescriptor.upvalue_count;
          upvalueIndex++
        ) {
          ops.push([
            `${code[i + 2 + upvalueIndex * 2] === 1 ? "LOCAL" : "UPVALUE"}(${
              code[i + 2 + upvalueIndex * 2 + 1]
            })`,
            null,
            true,
          ]);
        }

        i += opcodeSize + functionDescriptor.upvalue_count * 2 - 1;
      } else {
        ops.push([text, opStart]);
        i += opcodeSize - 1;
      }
    }

    return ops;
  }, [code, constants]);

  return (
    <div className="flex flex-col items-start">
      {ops.map(([op, offset, indent]) => (
        <div className="truncate" key={offset}>
          {offset !== null && <span className="text-xs ml-4">{offset}: </span>}
          <span className={classNames({ "ml-12": indent })}>
            <Badge
              text={op}
              color={offset === highlight ? "red" : "blue"}
              highlight={offset === highlight}
            />
          </span>
        </div>
      ))}
    </div>
  );
}
