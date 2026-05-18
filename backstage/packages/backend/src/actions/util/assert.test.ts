import { createAssertAction } from './assert';

describe('createAssertAction', () => {
  it('throws the provided message when the condition is false', async () => {
    const action = createAssertAction();

    await expect(
      action.handler({
        input: {
          condition: false,
          message: 'expected failure',
        },
      } as any),
    ).rejects.toThrow('expected failure');
  });

  it('does nothing when the condition is true', async () => {
    const action = createAssertAction();

    await expect(
      action.handler({
        input: {
          condition: true,
          message: 'unused',
        },
      } as any),
    ).resolves.toBeUndefined();
  });
});
