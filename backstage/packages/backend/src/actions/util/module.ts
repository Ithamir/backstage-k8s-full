import { createBackendModule } from '@backstage/backend-plugin-api';
import { scaffolderActionsExtensionPoint } from '@backstage/plugin-scaffolder-node/alpha';

import { createAssertAction } from './assert';

export const scaffolderUtilModule = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'util-actions',
  register(env) {
    env.registerInit({
      deps: {
        scaffolder: scaffolderActionsExtensionPoint,
      },
      async init({ scaffolder }) {
        scaffolder.addActions(createAssertAction());
      },
    });
  },
});

export default scaffolderUtilModule;
