import { createBackendModule } from '@backstage/backend-plugin-api';
import { scaffolderActionsExtensionPoint } from '@backstage/plugin-scaffolder-node/alpha';

import { createAssertAction } from './assert';
import { createFilterByAttributeAction } from './filterByAttribute';

export const scaffolderUtilActionsModule = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'util-actions',
  register(env) {
    env.registerInit({
      deps: {
        scaffolder: scaffolderActionsExtensionPoint,
      },
      async init({ scaffolder }) {
        scaffolder.addActions(
          createAssertAction(),
          createFilterByAttributeAction(),
        );
      },
    });
  },
});
