import classNames from "classnames";

export function Badge({ text, color, highlight }) {
  let colorClasses;

  if (color === "yellow") {
    colorClasses = [`bg-yellow-100`, `text-yellow-800`];
  } else if (color === "green") {
    colorClasses = [`bg-green-100`, `text-green-800`];
  } else if (color === "red") {
    colorClasses = [`bg-red-100`, `text-red-800`];
  } else if (color === "blue") {
    colorClasses = [`bg-blue-100`, `text-blue-800`];
  } else if (color === "indigo") {
    colorClasses = [`bg-indigo-100`, `text-indigo-800`];
  } else if (color === "purple") {
    colorClasses = [`bg-purple-100`, `text-purple-800`];
  } else if (color === "pink") {
    colorClasses = [`bg-pink-100`, `text-pink-800`];
  } else {
    throw "uknown color";
  }

  return (
    <span
      className={classNames(
        "inline-flex items-center px-2 py-0.5 m-2 rounded text-xs font-medium",
        colorClasses
      )}
      ref={(spanElement) => {
        if (spanElement && highlight) {
          spanElement.scrollIntoView({ behavior: "smooth", block: "center" });
        }
      }}
    >
      {text}
    </span>
  );
}
