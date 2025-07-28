# =============================================================
# 文件名(File): main_window_kivy.py
# 版本(Version): v2.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): KivyMD 版主界面，移除Android支持，专注桌面端体验
# =============================================================

# 字体路径（已下载到 assets/fonts/NotoSansSC-VariableFont_wght.ttf）
import os
from kivy.core.text import LabelBase
FONT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../assets/fonts/NotoSansSC-VariableFont_wght.ttf'))
LabelBase.register(name="NotoSansSC", fn_regular=FONT_PATH)

# 设置桌面端窗口大小
os.environ["KIVY_LOG_LEVEL"] = "error"

from kivy.lang import Builder
from kivy.properties import BooleanProperty, ObjectProperty, StringProperty, ListProperty
from kivy.clock import mainthread, Clock
from kivy.metrics import dp
import threading
import asyncio
import os

from kivymd.app import MDApp
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.card import MDCard
from kivymd.uix.label import MDLabel
from kivymd.uix.widget import Widget
from kivymd.uix.selectioncontrol import MDSwitch
from kivy.core.text import LabelBase
from kivy.core.window import Window
from kivymd.uix.textfield import MDTextField
from kivy.uix.behaviors import ButtonBehavior
from kivy.core.clipboard import Clipboard
from kivy.uix.screenmanager import ScreenManager, Screen
from ui.sys_config_window import APIConfigScreen


import re
import traceback
import os
import datetime
from kivy.utils import platform
from kivymd.uix.dialog import MDDialog
from kivymd.uix.button import MDFlatButton
from kivymd.uix.list import OneLineListItem

def clean_text(text):
    if not isinstance(text, str):
        return text
    # 去除常见不可见字符和替换符号，保留所有可打印的 Unicode 字符（多语言兼容）
    text = text.replace('\uFFFD', '').replace('\u200B', '').replace('\uFEFF', '')
    # 去除所有 C0/C1 控制字符（除换行、制表符外）
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]', '', text)
    # 去除字符串首尾空白
    return text.strip()

from audio_capture import AudioStream
from asr_client import VolcanoASRClientAsync
from lang_detect import LangDetect
from translator import Translator
# 新增导入
from hotwords import get_hotwords, add_hotword
from utils.file_downloader import FileDownloader

KV = '''
<MDLabel>:
    font_name: 'NotoSansSC'
<MDButtonText>:
    font_name: 'NotoSansSC'
<MDToolbar>:
    font_name: 'NotoSansSC'

<ChatBubble@MDCard>:
    orientation: 'vertical'
    adaptive_height: True
    size_hint_x: 1
    size_hint_y: None
    height: self.minimum_height
    padding: dp(10), dp(6)
    radius: [12, 12, 12, 12]
    md_bg_color: (0.1, 0.6, 0.9, 1) if self.selected else ((0.28, 0.38, 0.68, 1) if self.hovered else (.18, .18, .18, 1))
    elevation: 0
    # pos_hint: {"x": 0}  # 可选，已满宽无需定位
    MDLabel:
        text: root.corrected_text if root.corrected_text and root.corrected_text != root.original_text else root.original_text
        font_style: 'Body2'
        font_name: 'NotoSansSC'
        theme_text_color: 'Custom'
        text_color: 1, 1, 1, 1
        adaptive_height: True
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'
    MDLabel:
        text: root.translation if root.translation and app.show_translation else ''
        font_style: 'Body1'
        font_name: 'NotoSansSC'
        theme_text_color: 'Custom'
        text_color: .7, .7, .7, 1
        adaptive_height: True
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'
    MDLabel:
        text: root.timeout_tip if root.timeout_tip else ''
        font_style: 'Body1'
        font_name: 'NotoSansSC'
        theme_text_color: 'Custom'
        text_color: 1, 0.2, 0.2, 1
        adaptive_height: True
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'

<InterimBubble@MDCard>:
    orientation: 'vertical'
    adaptive_height: True
    size_hint_x: 1
    size_hint_y: None
    height: self.minimum_height
    padding: dp(10), dp(6)
    radius: [12, 12, 12, 12]
    md_bg_color: 1, 0.85, 0.2, 0.18
    elevation: 0
    # pos_hint: {"x": 0}
    MDLabel:
        text: root.text
        font_style: 'H5'
        font_name: 'NotoSansSC'
        italic: True
        theme_text_color: 'Custom'
        text_color: 1, 0.85, 0.2, 1
        adaptive_height: True
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'

<MainWidget>:
    orientation: 'vertical'
    md_bg_color: .12, .12, .12, 1
    MDTopAppBar:
        title: 'Translate Chat'
        right_action_items: [["chevron-right", lambda x: app.open_api_config()]]
        elevation: 0
        md_bg_color: app.theme_cls.primary_color

    ScrollView:
        size_hint_y: 1
        do_scroll_x: False
        MDBoxLayout:
            id: chat_area
            orientation: 'vertical'
            adaptive_height: True
            padding: dp(8), dp(8)
            spacing: dp(8)

    # 热词输入与显示区域
    MDBoxLayout:
        id: hotwords_box
        orientation: 'horizontal'
        size_hint_y: None
        height: dp(40)
        padding: dp(8), 0
        spacing: dp(8)
        MDTextField:
            id: hotword_input
            hint_text: ""
            font_name: 'NotoSansSC'
            size_hint_x: 0.5
            on_text_validate: root.add_hotword(self.text)
        MDLabel:
            id: hotwords_label
            text: root.hotwords_display
            font_name: 'NotoSansSC'
            size_hint_x: 1
            halign: 'left'
            valign: 'middle'

    MDBoxLayout:
        orientation: 'horizontal'
        size_hint_y: None
        height: dp(60)
        padding: dp(16), dp(8), dp(16), dp(16)
        spacing: dp(12)
        MDRaisedButton:
            text: 'Mic ON'
            on_release: root.on_mic()
            disabled: root.asr_running
        MDRaisedButton:
            text: 'Stop'
            on_release: root.on_stop()
        MDRaisedButton:
            text: 'Reset'
            on_release: root.on_reset()
        MDRaisedButton:
            text: 'DNLD'
            on_release: root.on_download()
        Widget:
        MDBoxLayout:
            orientation: 'horizontal'
            spacing: dp(8)
            size_hint_x: None
            width: self.minimum_width
            pos_hint: {"center_y": 0.5}
            MDSwitch:
                id: translate_switch
                size_hint: None, None
                size: dp(48), dp(32)
                pos_hint: {"center_y": 0.5}
                active: app.show_translation
                on_active: app.toggle_translation(self.active)

<MainScreen>:
    MainWidget:

'''

Builder.load_string(KV)

# ========== HoverBehavior ===========
from kivy.properties import BooleanProperty
class HoverBehavior(object):
    hovered = BooleanProperty(False)
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        Window.bind(mouse_pos=self.on_mouse_pos)
    def on_mouse_pos(self, *args):
        if not self.get_root_window():
            return
        pos = args[1]
        inside = self.collide_point(*self.to_widget(*pos))
        self.hovered = inside
    def on_hovered(self, instance, value):
        pass

class MainWidget(MDBoxLayout):
    asr_running = BooleanProperty(False)
    mic_btn_text = ObjectProperty('Mic ON')
    # 新增属性
    hotwords = ListProperty([])
    hotwords_display = StringProperty('[ ]')

    def __init__(self, **kwargs):
        # 启动时清空 hotwords.json
        try:
            hotwords_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../hotwords.json'))
            with open(hotwords_path, 'w', encoding='utf-8') as f:
                f.write('[]')
        except Exception as e:
            print(f"[热词] 清空hotwords.json失败: {e}")
        super().__init__(**kwargs)
        self.final_texts = []
        self.final_bubbles = []
        self.last_shown_definite_text = None
        self.final_utterance_keys = set()
        self.asr_thread = None
        self.audio = None
        self.lang_detect = LangDetect()
        self.translator = Translator()
        self.file_downloader = FileDownloader()
        self.loop = None
        self.interim_bubble = None  # 只保留一个interim气泡
        self._asr_call_count = 0  # 调用计数
        # 初始化热词
        self.hotwords = get_hotwords()
        self.update_hotwords_display()
        # 绑定键盘事件
        from kivy.core.window import Window
        Window.bind(on_key_down=self.on_key_down)

    def add_hotword(self, word):
        word = clean_text(word)
        if word and add_hotword(word):
            self.hotwords = get_hotwords()
            self.update_hotwords_display()
        self.ids.hotword_input.text = ''

    def update_hotwords_display(self):
        if self.hotwords:
            self.hotwords_display = '[' + '，'.join(self.hotwords) + '，]'
        else:
            self.hotwords_display = '[ ]'

    def on_mic(self):
        if self.asr_running:
            return
        self.set_asr_running(True)
        self.mic_btn_text = 'Mic OFF'
        self.audio = AudioStream()
        self.asr_thread = threading.Thread(target=self._run_asr, daemon=True)
        self.asr_thread.start()

    def on_stop(self):
        self.set_asr_running(False)
        if self.audio:
            self.audio.stop()
        self.mic_btn_text = 'Mic ON'
        if self.asr_thread and self.asr_thread.is_alive():
            self.asr_thread.join(timeout=1)

    def on_reset(self):
        self.final_texts.clear()
        self.final_bubbles.clear()
        self.last_shown_definite_text = None
        self.final_utterance_keys.clear()
        self.ids.chat_area.clear_widgets()
        self.scroll_to_bottom()

    def on_translate_checkbox_changed(self, active):
        pass  # 已废弃，统一用app.show_translation
        
    def on_download(self):
        """下载所有记录到txt文件"""
        if not self.final_bubbles:
            self.show_dialog("Notice", "No records to download")
            return
            
        # 使用文件下载器保存记录
        self.file_downloader.save_chat_records(
            self.final_bubbles, 
            callback=self.show_dialog
        )
    
    def show_dialog(self, title, text):
        """显示对话框"""
        dialog = MDDialog(
            title=title,
            text=text,
            buttons=[
                MDFlatButton(
                    text="确定",
                    on_release=lambda x: dialog.dismiss()
                )
            ]
        )
        dialog.open()

    @mainthread
    def set_asr_running(self, value):
        self.asr_running = value

    def _run_asr(self):
        try:
            asyncio.run(self._asr_flow())
        except Exception as e:
            print(f"[ASR] 错误: {e}")
            # 确保异常时也能安全切回主线程修改UI
            Clock.schedule_once(lambda dt: self.set_asr_running(False))

    async def _asr_flow(self):
        N = 10
        last_text = None
        last_emit_time = None
        no_update_count = 0
        audio = self.audio
        
        # 创建翻译任务队列和后台任务
        translation_queue = asyncio.Queue()
        translation_tasks = set()
        
        # 启动翻译后台任务
        translation_task = asyncio.create_task(self._translation_worker(translation_queue))
        
        async def on_result(response):
            nonlocal last_text, last_emit_time, no_update_count
            if not self.asr_running:
                return
            now = asyncio.get_event_loop().time()
            timeout_finalize = False
            if response.payload_msg:
                result = response.payload_msg.get('result', {})
                asr_utterances = result.get('utterances', [])
                updated = False
                current_text = None
                new_definite_utterances = []
                
                for utt in asr_utterances:
                    if utt.get('definite') and not utt.get('translation'):
                        # 立即显示ASR结果，翻译异步处理
                        utt['translation'] = None
                        utt['corrected'] = None
                        
                        # 将翻译任务加入队列，异步处理
                        if self.get_app_show_translation():
                            translation_item = {
                                'utterance_id': id(utt),
                                'text': utt['text'],
                                'utterance': utt
                            }
                            await translation_queue.put(translation_item)
                        
                        updated = True
                    if utt.get('text'):
                        current_text = utt['text']
                    if utt.get('definite') and utt.get('text'):
                        new_definite_utterances.append(utt)
                        
                if current_text and current_text != getattr(self, 'last_shown_definite_text', None):
                    self.last_shown_definite_text = current_text
                    no_update_count = 0
                    last_emit_time = now
                else:
                    no_update_count += 1
                    
                if no_update_count >= N and last_text:
                    timeout_finalize = True
                    utterance = {'text': last_text, 'definite': True, 'translation': None, 'timeout_finalize': True}
                    
                    # 超时固化时也异步翻译
                    if self.get_app_show_translation():
                        translation_item = {
                            'utterance_id': id(utterance),
                            'text': last_text,
                            'utterance': utterance
                        }
                        await translation_queue.put(translation_item)
                        
                    self._show_asr_utterances([utterance])
                    no_update_count = 0
                    last_emit_time = now
                else:
                    for utt in asr_utterances:
                        if utt.get('definite'):
                            utt['timeout_finalize'] = False
                    self._show_asr_utterances(asr_utterances)
                    last_emit_time = now
                    
        async with VolcanoASRClientAsync(on_result=on_result) as asr:
            try:
                await asr.run(audio.audio_stream_generator())
            except Exception as e:
                print(f"[ASR] 错误: {e}")
                
        # 等待翻译任务完成
        await translation_queue.put(None)  # 发送结束信号
        await translation_task
        
        self.set_asr_running(False)
        self.mic_btn_text = 'Mic ON'

    async def _translation_worker(self, queue):
        """翻译后台工作线程"""
        while True:
            try:
                item = await queue.get()
                if item is None:  # 结束信号
                    break
                    
                utterance_id = item['utterance_id']
                text = item['text']
                utterance = item['utterance']
                
                # 执行翻译
                try:
                    src_lang = self.lang_detect.detect(text)
                    tgt_lang = 'en' if src_lang.startswith('zh') else 'zh'
                    translation_result = await self.translator.translate(text, src_lang=src_lang, tgt_lang=tgt_lang)
                    
                    # 更新utterance的翻译结果
                    if isinstance(translation_result, dict):
                        utterance['translation'] = translation_result.get('translation', '')
                        utterance['corrected'] = translation_result.get('corrected', '')
                    else:
                        utterance['translation'] = translation_result or ''
                        utterance['corrected'] = ''
                        
                    # 在主线程中更新UI
                    self._update_utterance_translation(utterance)
                    
                except Exception as e:
                    print(f"[翻译] 翻译失败: {e}")
                    utterance['translation'] = '[翻译失败]'
                    utterance['corrected'] = text
                    self._update_utterance_translation(utterance)
                    
            except Exception as e:
                print(f"[翻译工作线程] 异常: {e}")
                continue

    @mainthread
    def _update_utterance_translation(self, utterance):
        """在主线程中更新utterance的翻译结果"""
        try:
            # 查找对应的气泡并更新翻译
            chat_area = self.ids.chat_area
            for child in chat_area.children:
                if hasattr(child, 'utterance_id') and child.utterance_id == id(utterance):
                    child.translation = utterance.get('translation', '')
                    child.corrected_text = utterance.get('corrected', '')
                    break
        except Exception as e:
            print(f"[UI更新] 更新翻译失败: {e}")

    def get_app_show_translation(self):
        # 兼容在主线程和子线程下获取app实例
        from kivy.app import App
        app = App.get_running_app()
        return getattr(app, 'show_translation', True)

    @mainthread
    def _show_asr_utterances(self, utterances):
        self._asr_call_count += 1
        # 移除过于详细的调试信息，只在需要时启用
        # print(f"[DEBUG] _show_asr_utterances call #{self._asr_call_count}, utterances count: {len(utterances)}")
        chat_area = self.ids.chat_area
        # print(f"[DEBUG] chat_area children before: {len(chat_area.children)}")
        # 1. 固化分句：增量添加到 final_bubbles，历史内容不丢失
        for utt in utterances:
            original_text = utt.get('text', '')
            definite = utt.get('definite', False)
            translation = utt.get('translation', None)
            corrected_text = utt.get('corrected', '')  # 获取纠错后的原文
            timeout_tip = '超时自动固化' if utt.get('timeout_finalize', False) else ''
            start_time = utt.get('start_time')
            end_time = utt.get('end_time')
            key = (original_text, start_time, end_time)
            if definite and original_text and key not in self.final_utterance_keys:
                utterance_id = id(utt)  # 使用utterance的id作为标识
                bubble = self.create_bubble(original_text, corrected_text, translation, timeout_tip, utterance_id)
                self.final_bubbles.append(bubble)
                self.final_utterance_keys.add(key)
        # 2. 清空并重绘所有固化分句
        chat_area.clear_widgets()
        for bubble in self.final_bubbles:
            chat_area.add_widget(bubble)
        # 3. 显示所有未固化 interim 气泡（每个都显示）
        for utt in utterances:
            text = utt.get('text', '')
            definite = utt.get('definite', False)
            if not definite and text:
                interim_bubble = InterimBubble(text=text)
                chat_area.add_widget(interim_bubble)
        # 4. 只有内容超出可视区时才自动滚动到底部
        scrollview = chat_area.parent
        if chat_area.height > scrollview.height:
            self.scroll_to_bottom()
        # print(f"[DEBUG] _show_asr_utterances end, chat_area children: {len(chat_area.children)}")

    def create_bubble(self, original_text, corrected_text, translation, timeout_tip, utterance_id=None):
        bubble = ChatBubble(
            original_text=clean_text(original_text), 
            corrected_text=clean_text(corrected_text) if corrected_text else '',
            translation=translation or '', 
            timeout_tip=timeout_tip or ''
        )
        if utterance_id:
            bubble.utterance_id = utterance_id
        return bubble

    @mainthread
    def scroll_to_bottom(self):
        chat_area = self.ids.chat_area
        if chat_area:
            chat_area.parent.scroll_y = 0

    def on_key_down(self, window, key, scancode, codepoint, modifiers):
        if 'ctrl' in modifiers and codepoint in ('c', 'C'):
            for bubble in self.final_bubbles:
                if getattr(bubble, 'selected', False):
                    # 复制内容：纠错后的文本（或原文）+ 翻译
                    copy_text = bubble.corrected_text if bubble.corrected_text and bubble.corrected_text != bubble.original_text else bubble.original_text
                    if bubble.translation:
                        copy_text += '\n翻译: ' + bubble.translation
                    Clipboard.copy(copy_text)
                    print(f"[复制] 已复制到剪贴板: {copy_text}")
                    break

class ChatBubble(HoverBehavior, MDCard):
    original_text = StringProperty()
    corrected_text = StringProperty()
    translation = StringProperty()
    timeout_tip = StringProperty()
    selected = BooleanProperty(False)

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            parent = self.parent
            for child in parent.children:
                if isinstance(child, ChatBubble):
                    child.selected = False
            self.selected = True
            return True
        return super().on_touch_down(touch)

class InterimBubble(MDCard):
    text = StringProperty()

class MainScreen(Screen):
    pass

class TranslateChatApp(MDApp):
    show_translation = BooleanProperty(True)
    def toggle_translation(self, value):
        self.show_translation = value
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Blue"
        try:
            from kivy.utils import platform
            if platform not in ("android", "ios"):
                Window.size = (360, 640)
        except Exception:
            pass
        sm = ScreenManager()
        sm.add_widget(MainScreen(name='main'))
        sm.add_widget(APIConfigScreen(name='api_config'))
        self.sm = sm
        return sm
    def open_api_config(self):
        self.sm.current = 'api_config'

def run_app():
    TranslateChatApp().run()

# 本地测试
if __name__ == '__main__':
    run_app() 