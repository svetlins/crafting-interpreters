export function pretty(source) {
  let lines = source.split("\n").map((line) => line.trim());

  lines = lines.filter((line, index) => {
    const previousLine = lines[index - 1] || "";

    return line === "" ? previousLine !== "" : true;
  });

  let nest = 0;

  for (let i = 0; i < lines.length - 1; i++) {
    const line = lines[i];

    if (line.includes("}")) nest -= 1;

    lines[i] = " ".repeat(nest * 2) + line;

    if (line.includes("{")) nest += 1;
  }

  return lines.join("\n");
}

export function shortLittleEndianToInteger(byte1, byte2) {
  let value = (byte2 << 8) + byte1;
  if (value > 2 ** 15) value = -1 * (2 ** 16 - value);
  return value;
}

export function loxObjectToString(loxObject) {
  if (typeof loxObject === "object" && loxObject.functionName) {
    return `fun ${loxObject.functionName}`;
  } else if (typeof loxObject === "boolean") {
    return loxObject ? "true" : "false";
  } else {
    return loxObject;
  }
}
