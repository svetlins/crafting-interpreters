/* eslint-disable jest/valid-title */
import fs from "fs";
import { VM } from "./VM";

fs.readdirSync("../test_suite/compiled").forEach((file) => {
  test(file, () => {
    const compiledExample = JSON.parse(
      fs.readFileSync(`../test_suite/compiled/${file}`).toString()
    );

    const vm = new VM(compiledExample.executable);
    vm.run();
    expect(vm.output.join("\n")).toBe(compiledExample.expected_output);
  });
});
