import { WebPlugin } from '@capacitor/core';

import type { DigitalInkPlugin } from './definitions';

export class DigitalInkWeb extends WebPlugin implements DigitalInkPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
