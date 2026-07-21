import { application } from "./application"
import AppController from "./app_controller"
import DropdownController from "./dropdown_controller"
import FlashController from "./flash_controller"
import ReaderController from "./reader_controller"
import TagEditorController from "./tag_editor_controller"
import LinkPickerController from "./link_picker_controller"
import AddFormController from "./add_form_controller"

application.register("app", AppController)
application.register("dropdown", DropdownController)
application.register("flash", FlashController)
application.register("reader", ReaderController)
application.register("tag-editor", TagEditorController)
application.register("link-picker", LinkPickerController)
application.register("add-form", AddFormController)
