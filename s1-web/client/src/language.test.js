/* eslint-disable jest/valid-title */
import fs from "fs";
import child_process from "child_process";
import { VM } from "./VM";

fs.readdirSync("../test_suite").forEach((file) => {
  test(file, (done) => {
    const source = fs.readFileSync(`../test_suite/${file}`).toString();

    const expectedOutput = source
      .split("\n")
      .filter((line) => line.includes("// => "))
      .map((line) => line.split(/\/\/ => /)[1])
      .join("\n");

    console.log(file);

    child_process.exec(`alox -c ../test_suite/${file}`, (error, stdout) => {
      if (error) {
        done(error);
        return;
      }

      try {
        const vm = new VM(JSON.parse(stdout));
        vm.run();
        expect(vm.output.join("\n")).toBe(expectedOutput);
        done();
      } catch (error) {
        done(error);
      }
    });
  });
});