import { useState } from "react";
import { MenuAlt2Icon, DotsHorizontalIcon } from "@heroicons/react/outline";
import { SearchIcon } from "@heroicons/react/solid";
import axios from "axios";

function classNames(...classes) {
  return classes.filter(Boolean).join(" ");
}

export default function App() {
  const [source, setSource] = useState("");
  const [tokens, setTokens] = useState([]);
  const [loading, setLoading] = useState(false);

  function submitSource(event) {
    setLoading(true);
    axios
      .post("http://localhost:4567/tokens", { source })
      .then((response) => {
        setTokens(response.data.tokens);
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
            <main className="flex-1 overflow-y-auto">
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
            <aside className="hidden w-96 bg-white border-l border-gray-200 overflow-y-auto lg:block relative">
              {loading && (
                <div className="w-full h-full opacity-50 bg-gray-300 absolute flex items-center justify-center">
                  <DotsHorizontalIcon className="h-12" />
                </div>
              )}
              {tokens.map((token) => (
                <Token tokenData={token} />
              ))}
            </aside>
          </div>
        </div>
      </div>
    </>
  );
}

function Token({ tokenData }) {
  let Component;

  if (tokenData.type === "STRING" || tokenData.type === "NUMBER") {
    Component = ValueToken;
  } else {
    Component = SimpleToken;
  }

  return <Component tokenData={tokenData} />;
}

function ValueToken({ tokenData }) {
  return (
    <span className="inline-flex items-center px-2 py-0.5 m-2 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
      {tokenData.type} ({tokenData.literal})
    </span>
  );
}

function SimpleToken({ tokenData }) {
  return (
    <span className="inline-flex items-center px-2 py-0.5 m-2 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
      {tokenData.type}
    </span>
  );
}
