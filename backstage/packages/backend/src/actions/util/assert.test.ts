import type { ActionContext } from '@backstage/plugin-scaffolder-node';

import { createAssertAction } from './assert';

type AssertActionInput = {
  condition: boolean;
  message: string;
};

function createActionContext(
  input: AssertActionInput,
): ActionContext<AssertActionInput> {
  return {
    input,
  } as ActionContext<AssertActionInput>;
}

describe('createAssertAction', () => {
  it('throws the provided message when the condition is false', async () => {
    const action = createAssertAction();

    await expect(
      action.handler(createActionContext({
        condition: false,
        message: 'expected failure',
      })),
    ).rejects.toThrow('expected failure');
  });

  it('does nothing when the condition is true', async () => {
    const action = createAssertAction();

    await expect(
      action.handler(createActionContext({
        condition: true,
        message: 'unused',
      })),
    ).resolves.toBeUndefined();
  });
});
