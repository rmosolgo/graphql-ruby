export class ActionCableUtil {
  /**
   * Generate a unique-ish random string suitable as part of ActionCable channel identifier
   *
   * @returns String unique-ish random string
   */
  static getUniqueChannelId = (): string => Math.round(Date.now() + Math.random() * 100000).toString(16)

  /**
   * Default ActionCable channel name
   */
  static DEFAULT_CHANNEL = "GraphqlChannel"
}
