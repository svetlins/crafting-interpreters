/* This example requires Tailwind CSS v2.0+ */
import { Fragment } from "react";
import { Menu, Transition } from "@headlessui/react";
import { ChevronDownIcon } from "@heroicons/react/solid";

function classNames(...classes) {
  return classes.filter(Boolean).join(" ");
}

export const presetSources = [
  { title: "Arithmetic", source: "print 1 + 2 * 3;" },
  {
    title: "Function",
    source: `
    fun fn(personName) {
      print "Hi," + personName + "!";
    }

    fn("Svetlin");
  `,
  },
  {
    title: "If",
    source: `
    if (1 + 2 > 3) {
      print "Oh, yes";
      print "It's true!";
    } else {
      print ":( it's false";
      print "Unfortunately ;(";
    }
  `,
  },
  {
    title: "Block",
    source: `var global = 100;

  {
    var block1 = "dummy";
    var block2 = 32 + 42;
    var block3 = 200;
    print block2 + block3;

    block1 = 100;
  }`,
  },
  {
    title: "Closure",
    source: `
      var global = 69;

      fun outer() {
        var closedOver = 666;

          fun doStuff(firstParam, secondParam) {
            var local = firstParam + secondParam;
            if (global + closedOver + local > 2) {
              local = local + 1;
              return local;
            } else {
              closedOver = closedOver + 1;
              return closedOver;
            }
          }

          print doStuff(1,2);
        }

        print outer();`,
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
