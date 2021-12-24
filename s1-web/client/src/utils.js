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
