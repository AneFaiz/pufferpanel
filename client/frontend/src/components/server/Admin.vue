<script setup>
import { ref, inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Ace from '@/components/ui/Ace.vue'
import Btn from '@/components/ui/Btn.vue'
import Icon from '@/components/ui/Icon.vue'
import Overlay from '@/components/ui/Overlay.vue'
import Tab from '@/components/ui/Tab.vue'
import Tabs from '@/components/ui/Tabs.vue'

import Variables from '@/components/template/Variables.vue'
import Install from '@/components/template/Install.vue'
import Hooks from '@/components/template/Hooks.vue'
import RunConfig from '@/components/template/RunConfig.vue'
import ServerEnvironment from '@/components/template/ServerEnvironment.vue'

const { t } = useI18n()
const toast = inject('toast')
const events = inject('events')
const router = useRouter()

const props = defineProps({
  server: { type: Object, required: true }
})

function editDefinition() {
  edit.value = JSON.stringify(def.value, undefined, 4)
  editorOpen.value = true
}

function cancelEdit() {
  editorOpen.value = false
}

function saveDefinition() {
  editorOpen.value = false
  const edited = JSON.parse(edit.value)
  props.server.updateDefinition(edited)
  def.value = edited
}

function deleteServer() {
  events.emit(
    'confirm',
    t('servers.ConfirmDelete', { name: props.server.name }),
    {
      text: t('servers.Delete'),
      icon: 'remove',
      color: 'error',
      action: async () => {
        props.server.delete()
        toast.success(t('servers.Deleted'))
        // delay 500ms to prevent running into sqlite dbs still being locked
        setTimeout(() => {router.push({ name: 'ServerList' })}, 500)
      }
    },
    {
      color: 'primary'
    }
  )
}

const def = ref({})
const edit = ref("")
const editorOpen = ref(false)

onMounted(async () => {
  if (props.server.hasScope('server.definition.view'))
    def.value = await props.server.getDefinition()
})
</script>

<template>
  <div class="admin">
    <h2 v-text="t('servers.Admin')" />
    <btn v-if="server.hasScope('server.definition.view')" v-hotkey="'a e'" variant="text" @click="editDefinition()"><icon name="edit" />{{ t('servers.EditDefinition') }}</btn>
    <btn v-if="server.hasScope('server.delete')" color="error" @click="deleteServer()"><icon name="remove" />{{ t('servers.Delete') }}</btn>

    <overlay v-model="editorOpen" class="server-definition">
      <tabs>
        <tab id="variables" :title="t('templates.Variables')" icon="variables" hotkey="t v">
          <variables v-model="edit" />
        </tab>
        <tab id="install" :title="t('templates.Install')" icon="install" hotkey="t i">
          <install v-model="edit" />
        </tab>
        <tab id="run" :title="t('templates.RunConfig')" icon="start" hotkey="t r">
          <run-config v-model="edit" />
        </tab>
        <tab id="hooks" :title="t('templates.Hooks')" icon="hooks" hotkey="t h">
          <hooks v-model="edit" />
        </tab>
        <tab id="environment" :title="t('templates.Environment')" icon="environment" hotkey="t e">
          <div class="warning" v-text="t('servers.EnvironmentEditHint')" />
          <server-environment v-model="edit" />
        </tab>
        <tab id="json" :title="t('templates.Json')" icon="json" hotkey="t j">
          <ace id="server-json" v-model="edit" class="server-json-editor" mode="json" />
        </tab>
      </tabs>
      <div class="actions">
        <btn v-hotkey="'Escape'" color="error" @click="cancelEdit()"><icon name="close" />{{ t('common.Cancel') }}</btn>
        <btn :disabled="server.hasScope('server.definition.edit')" color="primary" @click="saveDefinition()"><icon name="save" />{{ t('common.Save') }}</btn>
      </div>
    </overlay>
  </div>
</template>
