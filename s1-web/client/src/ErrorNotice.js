import { XCircleIcon, XIcon } from "@heroicons/react/solid";

export default function ErrorNotice({ errors, onClose }) {
  return (
    <div className="rounded-md bg-red-50 p-4">
      <div className="flex">
        <div className="flex-shrink-0">
          <XCircleIcon className="h-5 w-5 text-red-400" aria-hidden="true" />
        </div>
        <div className="ml-3">
          <h3 className="text-sm font-medium text-red-800">Errors:</h3>
          <div className="mt-2 text-sm text-red-700">
            <ul className="list-decimal l-5 space-y-1">
              {errors.map((error) => (
                <li>{error}</li>
              ))}
            </ul>
          </div>
        </div>
        <div className="flex-shrink-0 ml-auto">
          <button onClick={onClose}>
            <XIcon className="h-5 w-5" aria-hidden="true" />
          </button>
        </div>
      </div>
    </div>
  );
}
