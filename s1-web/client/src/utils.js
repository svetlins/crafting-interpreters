export function shortBigEndianToInteger(byte1, byte2) {
  let value = (byte1 << 8) + byte2;
  if (value > 2 ** 15) value = -1 * (2 ** 16 - value);
  return value;
}

export function loxValueInspect(loxValue) {
  if (typeof loxValue === "object") {
    if (loxValue && loxValue.functionName) {
      return `fun ${loxValue.functionName}/${loxValue.arity}`;
    } else {
      return JSON.stringify(loxValue);
    }
  } else if (typeof loxValue === "boolean") {
    return loxValue ? "true" : "false";
  } else if (typeof loxValue === "number") {
    if (loxValue.toFixed(0) === loxValue.toString()) {
      return `${loxValue}.0`;
    } else {
      return loxValue.toString();
    }
  } else {
    return loxValue.toString();
  }
}

export function loxValueToString(loxValue) {
  return loxValueInspect(loxValue);
}
