export interface DigitalInkPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
