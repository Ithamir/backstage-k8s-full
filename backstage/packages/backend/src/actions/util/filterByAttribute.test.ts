import { createFilterByAttributeAction } from './filterByAttribute';

type FilterByAttributeInput = {
  items?: Array<Record<string, unknown>>;
  attribute: string;
  values: string[];
  extract?: string;
};

function createActionContext(input: FilterByAttributeInput) {
  const outputs: Record<string, unknown> = {};
  const ctx = {
    input,
    output: (name: string, value: unknown) => {
      outputs[name] = value;
    },
  } as any;
  return { ctx, outputs };
}

describe('createFilterByAttributeAction', () => {
  const action = createFilterByAttributeAction();

  it('keeps only items whose attribute is in the allowed set', async () => {
    const { ctx, outputs } = createActionContext({
      items: [
        { type: 'ownedBy', targetRef: 'group:default/platform' },
        { type: 'dependencyOf', targetRef: 'component:default/foo' },
        { type: 'hasSubcomponent', targetRef: 'component:default/bar' },
      ],
      attribute: 'type',
      values: ['dependencyOf', 'hasSubcomponent'],
    });

    await action.handler(ctx);

    expect(outputs.count).toBe(2);
    expect(outputs.matches).toEqual([
      { type: 'dependencyOf', targetRef: 'component:default/foo' },
      { type: 'hasSubcomponent', targetRef: 'component:default/bar' },
    ]);
    expect(outputs.extracted).toEqual([]);
  });

  it('extracts the requested string attribute from each match', async () => {
    const { ctx, outputs } = createActionContext({
      items: [
        { type: 'ownedBy', targetRef: 'group:default/platform' },
        { type: 'dependencyOf', targetRef: 'component:default/foo' },
        { type: 'apiConsumedBy', targetRef: 'component:default/baz' },
      ],
      attribute: 'type',
      values: ['dependencyOf', 'apiConsumedBy'],
      extract: 'targetRef',
    });

    await action.handler(ctx);

    expect(outputs.count).toBe(2);
    expect(outputs.extracted).toEqual([
      'component:default/foo',
      'component:default/baz',
    ]);
  });

  it('returns zero matches when the items list is missing', async () => {
    const { ctx, outputs } = createActionContext({
      attribute: 'type',
      values: ['dependencyOf'],
      extract: 'targetRef',
    });

    await action.handler(ctx);

    expect(outputs.count).toBe(0);
    expect(outputs.matches).toEqual([]);
    expect(outputs.extracted).toEqual([]);
  });

  it('skips items whose attribute value is not a string', async () => {
    const { ctx, outputs } = createActionContext({
      items: [
        { type: 42, targetRef: 'component:default/skip' },
        { type: null, targetRef: 'component:default/skip-too' },
        { type: 'dependencyOf', targetRef: 'component:default/keep' },
      ],
      attribute: 'type',
      values: ['dependencyOf'],
      extract: 'targetRef',
    });

    await action.handler(ctx);

    expect(outputs.count).toBe(1);
    expect(outputs.extracted).toEqual(['component:default/keep']);
  });
});
