export function shortBigEndianToInteger(byte1, byte2) {
  let value = (byte1 << 8) + byte2;
  if (value > 2 ** 15) value = -1 * (2 ** 16 - value);
  return value;
}

export function loxObjectToString(loxObject) {
  if (typeof loxObject === "object") {
    if (loxObject && loxObject.functionName) {
      return `fun ${loxObject.functionName}`;
    } else {
      return JSON.stringify(loxObject);
    }
  } else if (typeof loxObject === "boolean") {
    return loxObject ? "true" : "false";
  } else {
    return loxObject;
  }
}
