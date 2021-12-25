/* This example requires Tailwind CSS v2.0+ */
import { Fragment } from "react";
import { Menu, Transition } from "@headlessui/react";
import { ChevronDownIcon } from "@heroicons/react/solid";

function classNames(...classes) {
  return classes.filter(Boolean).join(" ");
}

export const presetSources = [
  {
    title: "If",
    source: `
  if (1 + 2) {
    print "Oh, yes";
    print "It's true!";
  } else {
    print ":( it's false";
    print "Unfortunately ;(";
  }
  `,
  },
  {
    title: "Scope",
    source: `var outer = 100;

  {
    var dummy = "dummy";
    var x = 32 + 42;
    var y = 200;
    print x + y;

    outer = 100;
    x = 100;
  }`,
  },
  { title: "Arithmetic", source: "print 1 + 2 * 3;" },
  {
    title: "Closure",
    source: `
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

        print "123" + "456";`,
  },
];

export function PresetDropdown({ onChange }) {
  return (
    <div className="flex flex-col">
      <Menu as="div" className="relative inline-block text-left self-end">
        <div>
          <Menu.Button className="inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500">
            Presets
            <ChevronDownIcon
              className="-mr-1 ml-2 h-5 w-5"
              aria-hidden="true"
            />
          </Menu.Button>
        </div>

        <Transition
          as={Fragment}
          enter="transition ease-out duration-100"
          enterFrom="transform opacity-0 scale-95"
          enterTo="transform opacity-100 scale-100"
          leave="transition ease-in duration-75"
          leaveFrom="transform opacity-100 scale-100"
          leaveTo="transform opacity-0 scale-95"
        >
          <Menu.Items className="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none">
            <div className="py-1">
              {presetSources.map((presetSource) => (
                <Menu.Item>
                  {({ active }) => (
                    <button
                      type="button"
                      className={classNames(
                        "w-full text-left",
                        active ? "bg-gray-100 text-gray-900" : "text-gray-700",
                        "block px-4 py-2 text-sm"
                      )}
                      onClick={() => onChange(presetSource.source)}
                    >
                      {presetSource.title}
                    </button>
                  )}
                </Menu.Item>
              ))}
            </div>
          </Menu.Items>
        </Transition>
      </Menu>
    </div>
  );
}
