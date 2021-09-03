import { registerPlugin } from '@capacitor/core';

import type { DigitalInkPlugin } from './definitions';

const DigitalInk = registerPlugin<DigitalInkPlugin>('DigitalInk', {
  web: () => import('./web').then(m => new m.DigitalInkWeb()),
});

export * from './definitions';
export { DigitalInk };
