import { useState } from "react";
import { MenuAlt2Icon, DotsHorizontalIcon } from "@heroicons/react/outline";
import axios from "axios";
import Tree from "react-d3-tree";
import classNames from "classnames";

export default function App() {
  const [source, setSource] = useState("");
  const [tokens, setTokens] = useState([]);
  const [tree, setTree] = useState({
    name: "Svetlin",
    children: [{ name: "Eliza" }],
  });
  const [loading, setLoading] = useState(false);

  function submitSource(event) {
    setLoading(true);
    axios
      .post("http://localhost:4567/tokens", { source })
      .then((response) => {
        setTokens(response.data.tokens);
        setTree(response.data.tree);
      })
      .finally(() => setLoading(false));
    event.preventDefault();
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
            <main className="overflow-y-auto resize-x w-8/12">
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
                  </form>
                </div>
              </section>
            </main>

            {/* Secondary column (hidden on smaller screens) */}
            <aside className=" flex-1 min-w-[200px] bg-white border-l border-gray-200 overflow-y-auto relative flex flex-col">
              {loading && (
                <div className="w-full h-full opacity-50 bg-gray-300 absolute flex items-center justify-center">
                  <DotsHorizontalIcon className="h-12" />
                </div>
              )}
              <div>
                {tokens.map((token) => (
                  <TokenView tokenData={token} />
                ))}
              </div>

              <div className="w-full flex-1 mt-2 border-8">
                <Tree
                  data={tree}
                  initialDepth={100}
                  orientation="vertical"
                  pathFunc="straight"
                />
              </div>
            </aside>
          </div>
        </div>
      </div>
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
