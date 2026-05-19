import { createApp } from '@backstage/frontend-defaults';
import rbacPlugin from '@backstage-community/plugin-rbac/alpha';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import kubernetesPlugin from '@backstage/plugin-kubernetes/alpha';
import { navModule } from './modules/nav';
import { signInModule } from './modules/signIn';

export default createApp({
  features: [
    catalogPlugin,
    kubernetesPlugin,
    rbacPlugin,
    navModule,
    signInModule,
  ],
});
