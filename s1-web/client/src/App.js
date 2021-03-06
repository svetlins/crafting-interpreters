import {
  ChevronRightIcon,
  CogIcon,
  CubeIcon,
  DotsVerticalIcon,
} from "@heroicons/react/solid";
import classNames from "classnames";
import { useEffect, useRef, useState } from "react";
import Tree from "react-d3-tree";
import { Badge } from "./Badge";
import { PresetDropdown, presetSources } from "./components/PresetDropdown";
import ErrorNotice from "./ErrorNotice";
import { loxValueInspect } from "./utils";
import { VM } from "./VM";
import { ExecutableFunction } from "./ExecutableFunction";
import ALox from "./ALox";

const tabs = [
  { name: "Execute", icon: ChevronRightIcon },
  { name: "Tokens", icon: CubeIcon },
  { name: "AST", icon: DotsVerticalIcon },
  { name: "Bytecode", icon: CogIcon },
];

export default function App() {
  const [source, setSource] = useState(presetSources[0].source);

  const [currentTab, setCurrentTab] = useState("Execute");
  const [analysisResult, setAnalysisResult] = useState(null);
  const [errors, setErrors] = useState([]);

  function submitSource(event) {
    event.preventDefault();

    const result = JSON.parse(ALox.analyze(source));
    if (result.errors) {
      setErrors(result.errors);
    } else {
      setErrors([]);
      setAnalysisResult(result);
    }
  }

  return (
    <>
      <div className="h-full flex">
        {/* Content area */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {errors.length > 0 && (
            <ErrorNotice errors={errors} onClose={() => setErrors([])} />
          )}
          {/* Main content */}
          <div className="flex-1 flex items-stretch overflow-hidden">
            <main className="overflow-y-auto resize-x w-3/12">
              {/* Primary column */}
              <section
                aria-labelledby="primary-heading"
                className="relative min-w-0 flex-1 h-full flex flex-col lg:order-last"
              >
                {/* Content */}
                <div className="h-full p-3">
                  <form
                    className="h-full flex flex-col"
                    onSubmit={submitSource}
                  >
                    <div className="mb-2">
                      <PresetDropdown
                        onChange={(presetSource) => {
                          setAnalysisResult(null);
                          setSource(presetSource);
                        }}
                      />
                    </div>
                    <textarea
                      spellCheck={false}
                      name="comment"
                      id="comment"
                      className="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-indigo-300 border-4 resize-none rounded-md font-mono"
                      value={source}
                      onChange={(e) => setSource(e.target.value)}
                    />
                    <button
                      type="submit"
                      className="absolute bottom-8 right-8 btn"
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

              {analysisResult ? (
                <>
                  {currentTab === "Execute" && (
                    <ExecutionTab executable={analysisResult.executable} />
                  )}
                  {currentTab === "Tokens" && (
                    <TokensTab tokens={analysisResult.tokens} />
                  )}
                  {currentTab === "AST" && (
                    <ASTTab tree={analysisResult.tree} />
                  )}
                  {currentTab === "Bytecode" && (
                    <BytecodeTab executable={analysisResult.executable} />
                  )}
                </>
              ) : (
                <div className="self-center my-auto text-4xl text-gray-400 font-light italic">
                  Hit analyze to populate
                </div>
              )}
            </aside>
          </div>
        </div>
      </div>
    </>
  );
}

function ExecutionTab({ executable }) {
  const [vmState, setVMState] = useState();

  const vm = useRef();

  useEffect(() => {
    vm.current = new VM(executable);
    setVMState(vm.current.currentState());
  }, [executable]);

  if (vmState === undefined) {
    return null;
  }

  return (
    <div className="min-w-[900px] overflow-scroll">
      <div className="flex flex-row">
        <button
          className="btn my-4 mx-2 ml-4"
          disabled={vmState.terminated}
          type="button"
          onClick={() => {
            vm.current.step();
            setVMState(vm.current.currentState());
          }}
        >
          Step
        </button>
        <button
          className="btn my-4 mx-2"
          disabled={vmState.terminated}
          type="button"
          onClick={() => {
            vm.current.run();
            setVMState(vm.current.currentState());
          }}
        >
          Run to completion
        </button>
        <button
          className="btn my-4 mx-2"
          type="button"
          onClick={() => {
            vm.current.reset();
            setVMState(vm.current.currentState());
          }}
        >
          Reset
        </button>
      </div>
      <div className="flex flex-col m-4">
        <div className="flex flex-row items-start">
          <div className="flex-1 mr-8">
            <div className="pb-5 border-b border-gray-200">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Call Stack / Code
              </h3>
            </div>
            <div className="h-96 overflow-y-scroll pt-2">
              {vmState.callFrames.map((callFrame, index) => (
                <div className="font-mono m-4" key={index}>
                  {callFrame.functionName}@{callFrame.ip()}
                </div>
              ))}
              <ExecutableFunction
                executable={executable}
                functionName={vmState.callFrame?.functionName || "__toplevel__"}
                highlight={vmState.callFrame?.ip()}
              />
            </div>
          </div>

          <div className="flex-1 mr-8">
            <div className="flex flex-col pb-5 border-b border-gray-200 overflow-y-scroll">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Globals
              </h3>
            </div>
            <div className="h-96 overflow-y-scroll flex flex-col items-start pt-2">
              {Object.entries(vmState.globals || {}).map(
                ([globalName, globalValue], index) => (
                  <span>
                    <Badge
                      text={globalName}
                      color="purple"
                      highlight={
                        index === Object.keys(vmState?.globals).length - 1
                      }
                    />
                    <span className="text-xs">=</span>
                    <Badge text={loxValueInspect(globalValue)} color="yellow" />
                  </span>
                )
              )}
            </div>
          </div>

          <div className="flex-1">
            <div className="pb-5 border-b border-gray-200">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Stack
              </h3>
            </div>
            <div className="flex flex-col-reverse items-start h-96 overflow-y-scroll pt-2">
              {(vmState.stack || []).map((value, index) => (
                <Badge
                  text={loxValueInspect(value)}
                  color={
                    index === vmState.callFrame?.stackTop - 1 ? "red" : "yellow"
                  }
                  highlight={index === vmState.stack.length - 1}
                />
              ))}
            </div>
          </div>
        </div>
        <code className="block bg-gray-100 font-mono m-4 mt-8 p-2">
          {vmState.output.length > 0
            ? vmState.output.map((line) => <div>{line}</div>)
            : "no output"}
        </code>
      </div>
    </div>
  );
}

function TokensTab({ tokens }) {
  return (
    <div>
      {tokens.map((token) => {
        if (
          token.type === "STRING" ||
          token.type === "NUMBER" ||
          token.type === "IDENTIFIER"
        ) {
          return (
            <Badge
              text={`${token.type} (${token.literal || token.lexeme})`}
              color="green"
            />
          );
        } else {
          return <Badge text={token.type} color="yellow" />;
        }
      })}
    </div>
  );
}

function ASTTab({ tree }) {
  return (
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
  );
}

function BytecodeTab({ executable }) {
  const functions = Object.keys(executable.functions);

  return (
    <>
      {functions.map((fn) => (
        <div>
          <h1 className="px-2 py-0.5 italic text-gray-500 text-sm">{fn}:</h1>
          <ExecutableFunction executable={executable} functionName={fn} />
        </div>
      ))}
    </>
  );
}
