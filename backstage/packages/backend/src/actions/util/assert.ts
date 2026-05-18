import { createTemplateAction } from '@backstage/plugin-scaffolder-node';

const assertActionId = 'util:assert';

export function createAssertAction() {
  return createTemplateAction({
    id: assertActionId,
    description: 'Fails the task when the provided condition is false.',
    schema: {
      input: {
        condition: z => z.boolean(),
        message: z => z.string(),
      },
    },
    async handler(ctx) {
      const { condition, message } = ctx.input;

      if (!condition) {
        throw new Error(message);
      }
    },
  });
}
