import { createTemplateAction } from '@backstage/plugin-scaffolder-node';

const filterByAttributeActionId = 'util:filterByAttribute';

export function createFilterByAttributeAction() {
  return createTemplateAction({
    id: filterByAttributeActionId,
    description:
      'Filters a list of objects, keeping those whose named attribute matches one of the provided values. Optionally extracts a string attribute from each match.',
    schema: {
      input: {
        items: z =>
          z
            .array(z.record(z.string(), z.any()))
            .optional()
            .describe('Objects to filter. Defaults to an empty list.'),
        attribute: z =>
          z.string().describe('Object key whose value is matched against `values`.'),
        values: z =>
          z.array(z.string()).describe('Allowed string values for the named attribute.'),
        extract: z =>
          z
            .string()
            .optional()
            .describe(
              'Optional object key whose string value is collected from each matching item.',
            ),
      },
      output: {
        matches: z =>
          z
            .array(z.record(z.string(), z.any()))
            .describe('Items whose attribute value is in `values`.'),
        count: z => z.number().describe('Number of matching items.'),
        extracted: z =>
          z
            .array(z.string())
            .describe(
              'String values pulled from `extract` on each match, in input order. Empty when `extract` is not set.',
            ),
      },
    },
    async handler(ctx) {
      const { items = [], attribute, values, extract } = ctx.input;
      const allowed = new Set(values);

      const matches = items.filter(item => {
        const value = item[attribute];
        return typeof value === 'string' && allowed.has(value);
      });

      const extracted = extract
        ? matches
            .map(item => item[extract])
            .filter((value): value is string => typeof value === 'string')
        : [];

      ctx.output('matches', matches);
      ctx.output('count', matches.length);
      ctx.output('extracted', extracted);
    },
  });
}
