import { createTemplateAction } from '@backstage/plugin-scaffolder-node';

export function createAssertAction() {
  return createTemplateAction({
    id: 'util:assert',
    description: 'Fails the task when the provided condition is false.',
    schema: {
      input: {
        condition: z => z.boolean(),
        message: z => z.string(),
      },
    },
    async handler(ctx) {
      if (!ctx.input.condition) {
        throw new Error(ctx.input.message);
      }
    },
  });
}
