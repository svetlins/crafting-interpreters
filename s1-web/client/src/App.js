import { useState } from "react";
import { MenuAlt2Icon, DotsHorizontalIcon } from "@heroicons/react/outline";
import { CubeIcon, DotsVerticalIcon, CogIcon } from "@heroicons/react/solid";
import axios from "axios";
import Tree from "react-d3-tree";
import classNames from "classnames";

const tabs = [
  { name: "Tokens", href: "#", icon: CubeIcon },
  { name: "AST", href: "#", icon: DotsVerticalIcon },
  { name: "Bytecode", href: "#", icon: CogIcon },
];

const analyzeUrl = process.env.REACT_APP_ANALYZE_ENDPOINT_URL || "/api/analyze";

function pretty(source) {
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

export default function App() {
  const [source, setSource] = useState(
    pretty(`
      var y = 69;

      fun outer() {
        var z = 666;

          fun doStuff(a, b, c) {
            var x = a + b + c;
            if (x + y + z > 2) {
              x = x + 1;
              return x;
            } else {
              return -1;
            }
          }

          print doStuff(1,2,3);
        }

        print "123" + "456";
  `)
  );

  const [tokens, setTokens] = useState([]);
  const [currentTab, setCurrentTab] = useState("Tokens");
  const [tree, setTree] = useState(null);
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
                <span className="sr-only">Open sidebar</span>
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
                className="min-w-0 flex-1 h-full flex flex-col lg:order-last"
              >
                {/* Your content */}
                <div className="h-full m-3 relative">
                  <form className="h-full" onSubmit={submitSource}>
                    <textarea
                      name="comment"
                      id="comment"
                      className="h-full shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-indigo-300 border-4 resize-none rounded-md"
                      value={source}
                      onChange={(e) => setSource(e.target.value)}
                    />
                    <button
                      type="submit"
                      className="absolute bottom-4 right-4 px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Analyze
                    </button>
                    <button
                      type="button"
                      className="absolute bottom-4 left-4 px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-gray-600 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                      onClick={prettifySource}
                    >
                      Pretify
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
                    <a
                      key={tab.name}
                      href={tab.href}
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
                    </a>
                  ))}
                </nav>
              </div>

              {tokens.length > 0 ? (
                <Content tokens={tokens} tree={tree} currentTab={currentTab} />
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

function Content({ tokens, tree, currentTab }) {
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
    </>
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
    <Token
      text={`${tokenData.type} (${tokenData.literal || tokenData.lexeme})`}
      color="green"
    />
  );
}

function SimpleToken({ tokenData }) {
  return <Token text={tokenData.type} color="yellow" />;
}

function Token({ text, color }) {
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
