import { removeClientFieldsFromString } from "../removeClientFields"


describe("removing @client fields", () => {
  function normalizeString(str: string) {
    return str.replace(/\s+/g, " ").trim()
  }

  it("returns a string without any fields with @client", () => {
    var newString = removeClientFieldsFromString("{ f1 f2 @client { a b } f3 { a b @client } }")
    var expectedString = "{ f1 f3 { a } }"
    expect(normalizeString(newString)).toEqual(expectedString)
  })
  it("leaves other strings unchanged", () => {
    var originalString = "{ f1 f2 @other { a b } f3 { a b @notClient } }"
    var newString = removeClientFieldsFromString(originalString)
    expect(normalizeString(newString)).toEqual(originalString)
  })
})
