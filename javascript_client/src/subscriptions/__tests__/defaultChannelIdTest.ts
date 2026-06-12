import defaultChannelId from "../defaultChannelId"

describe("defaultChannelId", () => {
  const originalDescriptor = Object.getOwnPropertyDescriptor(crypto, "randomUUID")

  afterEach(() => {
    if (originalDescriptor) {
      Object.defineProperty(crypto, "randomUUID", originalDescriptor)
    }
  })

  it("uses crypto.randomUUID when available", () => {
    Object.defineProperty(crypto, "randomUUID", {
      value: () => "11111111-2222-3333-4444-555555555555",
      configurable: true,
      writable: true,
    })

    expect(defaultChannelId()).toEqual("11111111-2222-3333-4444-555555555555")
  })

  it("falls back to crypto.getRandomValues on insecure contexts, where crypto.randomUUID is not exposed", () => {
    Object.defineProperty(crypto, "randomUUID", {
      value: undefined,
      configurable: true,
      writable: true,
    })

    expect(defaultChannelId()).toMatch(/^[0-9a-f]{32}$/)
  })

  it("generates unique ids without crypto.randomUUID", () => {
    Object.defineProperty(crypto, "randomUUID", {
      value: undefined,
      configurable: true,
      writable: true,
    })

    const ids = new Set(Array.from({ length: 1000 }, () => defaultChannelId()))

    expect(ids.size).toEqual(1000)
  })
})
