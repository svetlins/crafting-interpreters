import { useEffect, useMemo, useState } from "react";
import { MenuAlt2Icon, DotsHorizontalIcon } from "@heroicons/react/outline";
import {
  CubeIcon,
  DotsVerticalIcon,
  CogIcon,
  ChevronRightIcon,
} from "@heroicons/react/solid";
import axios from "axios";
import Tree from "react-d3-tree";
import classNames from "classnames";

import { pretty } from "./utils";
import { PresetDropdown, presetSources } from "./components/PresetDropdown";
import { createVM } from "./VM";

const tabs = [
  { name: "Tokens", icon: CubeIcon },
  { name: "AST", icon: DotsVerticalIcon },
  { name: "Bytecode", icon: CogIcon },
  { name: "Execute", icon: ChevronRightIcon },
];

const analyzeUrl = process.env.REACT_APP_ANALYZE_ENDPOINT_URL || "/api/analyze";

export default function App() {
  const [source, setSource] = useState(pretty(presetSources[0].source));

  const [currentTab, setCurrentTab] = useState("Tokens");
  const [tokens, setTokens] = useState([]);
  const [tree, setTree] = useState(null);
  const [executable, setExecutable] = useState(null);
  const [loading, setLoading] = useState(false);

  function submitSource(event) {
    prettifySource();
    setLoading(true);
    const startedAt = new Date();
    axios.post(analyzeUrl, { source }).then((response) => {
      setTimeout(() => {
        setLoading(false);
        setTokens(response.data.tokens);
        setTree(response.data.tree);
        setExecutable(response.data.executable);
      }, Math.max(1500, new Date() - startedAt));
    });
    event.preventDefault();
  }

  function prettifySource() {
    setSource(pretty(source));
  }

  return (
    <>
      <div className="h-full flex">
        {/* Content area */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <header className="w-full">
            <div className="relative z-10 flex-shrink-0 h-16 bg-white border-b border-gray-200 shadow-sm flex">
              <button
                type="button"
                className="border-r border-gray-200 px-4 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500 md:hidden"
              >
                <MenuAlt2Icon className="h-6 w-6" aria-hidden="true" />
              </button>
              <div className="flex-1 flex justify-between px-4 sm:px-6">
                <div className="flex-1 flex"></div>
                <div className="ml-2 flex items-center space-x-4 sm:ml-6 sm:space-x-6">
                  <button
                    type="button"
                    className="flex bg-indigo-600 p-1 rounded-full items-center justify-center text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    <DotsHorizontalIcon
                      className="h-6 w-6"
                      aria-hidden="true"
                    />
                    <span className="sr-only">Add file</span>
                  </button>
                </div>
              </div>
            </div>
          </header>

          {/* Main content */}
          <div className="flex-1 flex items-stretch overflow-hidden">
            <main className="overflow-y-auto resize-x w-4/12">
              {/* Primary column */}
              <section
                aria-labelledby="primary-heading"
                className="relative min-w-0 flex-1 h-full flex flex-col lg:order-last"
              >
                {/* Content */}
                <div className="h-full m-3">
                  <form className="h-full" onSubmit={submitSource}>
                    <div className="mb-2">
                      <PresetDropdown
                        onChange={(presetSource) => {
                          setTokens([]);
                          setSource(pretty(presetSource));
                        }}
                      />
                    </div>
                    <textarea
                      spellCheck={false}
                      name="comment"
                      id="comment"
                      className="h-full shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-indigo-300 border-4 resize-none rounded-md font-mono"
                      value={source}
                      onChange={(e) => setSource(e.target.value)}
                    />
                    <button
                      type="submit"
                      className="absolute bottom-4 right-6 btn"
                    >
                      Analyze
                    </button>
                  </form>
                </div>
              </section>
            </main>

            {/* Secondary column (hidden on smaller screens) */}
            <aside className="flex-1 min-w-[200px] bg-white border-l border-gray-200 overflow-y-auto relative flex flex-col">
              <div className="border-b border-gray-200 px-2">
                <nav className="-mb-px flex space-x-8" aria-label="Tabs">
                  {tabs.map((tab) => (
                    <button
                      type="button"
                      key={tab.name}
                      className={classNames(
                        tab.name === currentTab
                          ? "border-indigo-500 text-indigo-600"
                          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300",
                        "group inline-flex items-center py-4 px-1 border-b-2 font-medium text-sm"
                      )}
                      onClick={() => setCurrentTab(tab.name)}
                    >
                      <tab.icon
                        className={classNames(
                          tab.current
                            ? "text-indigo-500"
                            : "text-gray-400 group-hover:text-gray-500",
                          "-ml-0.5 mr-2 h-5 w-5"
                        )}
                        aria-hidden="true"
                      />
                      <span>{tab.name}</span>
                    </button>
                  ))}
                </nav>
              </div>

              {tokens.length > 0 ? (
                <Content
                  tokens={tokens}
                  tree={tree}
                  currentTab={currentTab}
                  executable={executable}
                />
              ) : (
                <div className="self-center my-auto text-4xl text-gray-400 font-light italic">
                  Hit analyze to populate
                </div>
              )}

              {loading && (
                <div className="w-full h-full opacity-50 bg-gray-300 absolute flex items-center justify-center">
                  <DotsHorizontalIcon className="h-12" />
                </div>
              )}
            </aside>
          </div>
        </div>
      </div>
    </>
  );
}

function Content({ tokens, tree, executable, currentTab }) {
  return (
    <>
      {currentTab === "Tokens" && (
        <div>
          {tokens.map((token) => (
            <TokenView tokenData={token} />
          ))}
        </div>
      )}

      {currentTab === "AST" && (
        <div className="w-full flex-1">
          <div className="h-full">
            {tree ? (
              <Tree
                data={tree}
                initialDepth={1}
                orientation="horizontal"
                pathFunc="step"
                translate={{ x: 200, y: 350 }}
              />
            ) : (
              <span className="">Empty</span>
            )}
          </div>
        </div>
      )}

      {currentTab === "Bytecode" && executable && renderOpcodes(executable)}
      {currentTab === "Execute" && executable && (
        <ExecutionResult executable={executable} />
      )}
    </>
  );
}

function ExecutionResult({ executable }) {
  const [vmState, setVMState] = useState();

  const vm = useMemo(() => {
    return createVM(executable);
  }, [executable]);

  useEffect(() => {
    setVMState(vm.reset());
  }, [vm, executable]);

  if (vmState === undefined) {
    return null;
  }

  return (
    <div className="m-2">
      <div className="flex flex-row">
        <button
          className="btn m-2"
          disabled={vmState.terminated}
          type="button"
          onClick={() => {
            setVMState(vm.tick());
          }}
        >
          Tick
        </button>
        <button
          className="btn m-2"
          disabled={vmState.terminated}
          type="button"
          onClick={() => {
            let terminated = false;

            while (!terminated) {
              const intermediateVMState = vm.tick();
              terminated = intermediateVMState.terminated;
            }

            setVMState(vm.tick());
          }}
        >
          Run to completion
        </button>
        <button
          className="btn m-2"
          type="button"
          onClick={() => setVMState(vm.reset())}
        >
          Reset
        </button>
      </div>
      <Badge text={vmState.nextOp || "N/A"} color="yellow" />
      <table className="m-2 border-collapse">
        <tbody>
          {(vmState.callFrame?.code || []).map((value, index) => (
            <tr
              className={classNames("border-2 border-gray-100", {
                "bg-red-200": index === vmState.callFrame.ip(),
              })}
            >
              <Badge text={value} color="yellow" />
            </tr>
          ))}
        </tbody>
      </table>
      <div className="flex flex-row m-2">
        {(vmState.stack || []).map((value, index) => (
          <div
            className={classNames("border-2 border-collapse", {
              "border-red-500": index === vmState.callFrame?.stackTop,
            })}
          >
            <Badge text={JSON.stringify(value)} color="yellow" />
          </div>
        ))}
      </div>
      <code className="block bg-gray-100 font-mono m-2 p-2">
        {vmState.output || "no output"}
      </code>
      <table className="font-mono">
        <tbody>
          {Object.entries(vmState.globals || {}).map(
            ([globalName, globalValue]) => (
              <tr>
                <td className="px-2">{globalName}</td>
                <td className="px-2">{globalValue}</td>
              </tr>
            )
          )}
        </tbody>
      </table>
      callFrames: {JSON.stringify(vmState.callFrames)}
    </div>
  );
}

function TokenView({ tokenData }) {
  let Component;

  if (
    tokenData.type === "STRING" ||
    tokenData.type === "NUMBER" ||
    tokenData.type === "IDENTIFIER"
  ) {
    Component = ValueToken;
  } else {
    Component = SimpleToken;
  }

  return <Component tokenData={tokenData} />;
}

function ValueToken({ tokenData }) {
  return (
    <Badge
      text={`${tokenData.type} (${tokenData.literal || tokenData.lexeme})`}
      color="green"
    />
  );
}

function SimpleToken({ tokenData }) {
  return <Badge text={tokenData.type} color="yellow" />;
}

function Badge({ text, color }) {
  let colorClasses;

  if (color === "yellow") {
    colorClasses = [`bg-yellow-100`, `text-yellow-800`];
  } else if (color === "green") {
    colorClasses = [`bg-green-100`, `text-green-800`];
  } else {
    throw "uknown color";
  }

  return (
    <span
      className={classNames(
        "inline-flex items-center px-2 py-0.5 m-2 rounded text-xs font-medium",
        colorClasses
      )}
    >
      {text}
    </span>
  );
}

const opcodeSizes = {
  "LOAD-CONSTANT": 2,
  "LOAD-CLOSURE": 2,
  "DEFINE-GLOBAL": 2,
  "SET-GLOBAL": 2,
  "GET-GLOBAL": 2,
  "SET-LOCAL": 2,
  "GET-LOCAL": 2,
  "INIT-HEAP": 2,
  "SET-HEAP": 2,
  "GET-HEAP": 2,
  "JUMP-ON-FALSE": 3,
  CALL: 2,
  JUMP: 3,
};
function renderOpcodes(executable) {
  let elements = [];

  const functions = Object.keys(executable);

  for (let fn of functions) {
    const code = executable[fn].code;
    const constants = executable[fn].constants;

    elements.push(
      <h1 className="px-2 py-0.5 italic text-gray-500 text-sm">{fn}:</h1>
    );

    for (let i = 0; i < code.length; i++) {
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
        text = `${i}: ${opcode} ( $${constantIndex} = ${JSON.stringify(
          constants[constantIndex]
        )})`;
      } else if (opcode === "LOAD-CLOSURE") {
        const constantIndex = code[i + 1];
        const functionDescriptor = constants[constantIndex];
        text = `${i}: ${opcode} ( fun ${functionDescriptor.name}/${functionDescriptor.arity} )`;
      } else if (opcodeSize > 1) {
        const args = code.slice(i + 1, i + opcodeSize);
        text = `${i}: ${opcode} ( arg = ${args.join(", ")})`;
      } else {
        text = `${i}: ${opcode}`;
      }

      i += opcodeSize - 1;

      elements.push(
        <div>
          <Badge text={text} color="yellow" />
        </div>
      );
    }
  }
  return elements;
}
