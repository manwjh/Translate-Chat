# =============================================================
# 文件名(File): main_window_kivy.py
# 版本(Version): v2.0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/07/29
# 简介(Description): KivyMD 版主界面，移除Android支持，专注桌面端体验
# =============================================================

# 使用系统字体，支持多语言显示
import os
import sys

# 设置桌面端窗口大小
os.environ["KIVY_LOG_LEVEL"] = "error"

# 确保UTF-8编码
if sys.platform.startswith('darwin'):  # macOS
    os.environ['PYTHONIOENCODING'] = 'utf-8'
    os.environ['LC_ALL'] = 'zh_CN.UTF-8'
    os.environ['LANG'] = 'zh_CN.UTF-8'

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
from kivy.uix.textinput import TextInput
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
    try:
        # 确保文本是UTF-8编码
        if isinstance(text, bytes):
            text = text.decode('utf-8')
        elif isinstance(text, str):
            # 重新编码确保UTF-8
            text.encode('utf-8').decode('utf-8')
        
        # 去除常见不可见字符和替换符号，保留所有可打印的 Unicode 字符（多语言兼容）
        text = text.replace('\uFFFD', '').replace('\u200B', '').replace('\uFEFF', '')
        # 去除所有 C0/C1 控制字符（除换行、制表符外）
        text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]', '', text)
        # 去除字符串首尾空白
        return text.strip()
    except UnicodeError as e:
        print(f"[ERROR] Unicode error in clean_text: {e}, text: {repr(text)}")
        return str(text) if text else ""

from audio_capture import AudioStream
from asr_client import VolcanoASRClientAsync
from lang_detect import LangDetect
from translator import Translator
# 新增导入
from hotwords import get_hotwords, add_hotword
from utils.file_downloader import FileDownloader

# 使用系统注册的字体，支持中文显示
# 确保字体只注册一次，避免重复注册
try:
    from utils.font_utils import register_system_font
    font_name = register_system_font()
    print(f"[DEBUG] Main window font registered: {font_name}")
except Exception as e:
    print(f"[DEBUG] Main window font registration failed: {e}")
    font_name = 'Roboto'

KV = '''

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
    Label:
        text: root.get_display_text()
        font_name: 'SystemFont'
        font_size: '16sp'
        color: 1, 1, 1, 1
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'

    Label:
        text: root.translation if root.translation and app.show_translation else ''
        font_name: 'SystemFont'
        font_size: '14sp'
        color: .7, .7, .7, 1
        size_hint_x: 1
        size_hint_y: None
        height: self.texture_size[1]
        text_size: self.width, None
        halign: 'left'
        valign: 'middle'
    Label:
        text: root.timeout_tip if root.timeout_tip else ''
        font_name: 'SystemFont'
        font_size: '12sp'
        color: 1, 0.2, 0.2, 1
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
    Label:
        text: root.text
        font_name: 'SystemFont'
        font_size: '18sp'
        italic: True
        color: 1, 0.85, 0.2, 1
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
        title: "Translate Chat"
        right_action_items: [["menu", lambda x: app.open_api_config()]]
        elevation: 4
        md_bg_color: app.theme_cls.primary_color
        pos_hint: {'top': 1}
        size_hint_y: None
        height: dp(56)

    ScrollView:
        size_hint_y: 1
        do_scroll_x: False
        pos_hint: {'top': 0.9, 'bottom': 0.2}
        MDBoxLayout:
            id: chat_area
            orientation: 'vertical'
            adaptive_height: True
            padding: dp(8), dp(8)
            spacing: dp(8)



    MDBoxLayout:
        orientation: 'horizontal'
        size_hint_y: None
        height: dp(60)
        padding: dp(16), dp(8), dp(16), dp(16)
        spacing: dp(12)
        MDRaisedButton:
            text: 'Mic ON'
            font_name: 'SystemFont'
            on_release: root.on_mic()
            disabled: root.asr_running
        MDRaisedButton:
            text: 'Stop'
            font_name: 'SystemFont'
            on_release: root.on_stop()
        MDRaisedButton:
            text: 'Reset'
            font_name: 'SystemFont'
            on_release: root.on_reset()
        MDRaisedButton:
            text: 'DNLD'
            font_name: 'SystemFont'
            on_release: root.on_download()
        Widget:
        # 翻译开关已移动到系统配置页面

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
    # 热词相关属性（保留代码结构）
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
        # 初始化热词（保留代码结构）
        self.hotwords = get_hotwords()
        self.update_hotwords_display()
        # 绑定键盘事件
        from kivy.core.window import Window
        Window.bind(on_key_down=self.on_key_down)

    def add_hotword(self, word):
        # 热词添加方法（保留代码结构）
        word = clean_text(word)
        if word and add_hotword(word):
            self.hotwords = get_hotwords()
            self.update_hotwords_display()
        # self.ids.hotword_input.text = ''  # 已移除UI元素

    def update_hotwords_display(self):
        # 热词显示更新方法（保留代码结构）
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

    # 翻译开关已移动到系统配置页面
        
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
            print("[DEBUG] ASR原始payload_msg:", repr(response.payload_msg))  # 新增调试打印
            nonlocal last_text, last_emit_time, no_update_count
            if not self.asr_running:
                return
            now = asyncio.get_event_loop().time()
            timeout_finalize = False
            if response.payload_msg:
                result = response.payload_msg.get('result', {})
                asr_utterances = result.get('utterances', [])
                print("[DEBUG] ASR原始utterances:", repr(asr_utterances))  # 新增调试打印
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
                
                print("[DEBUG] 翻译前文本:", repr(text))  # 新增调试打印
                # 执行翻译
                try:
                    src_lang = self.lang_detect.detect(text)
                    tgt_lang = 'en' if src_lang.startswith('zh') else 'zh'
                    translation_result = await self.translator.translate(text, src_lang=src_lang, tgt_lang=tgt_lang)
                    print("[DEBUG] 翻译API返回:", repr(translation_result))  # 新增调试打印
                    
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
            print(f"[DEBUG] _update_utterance_translation: utterance_id={id(utterance)}, translation={repr(utterance.get('translation', ''))}, corrected={repr(utterance.get('corrected', ''))}")
            # 查找对应的气泡并更新翻译
            chat_area = self.ids.chat_area
            for child in chat_area.children:
                if hasattr(child, 'utterance_id') and child.utterance_id == id(utterance):
                    print(f"[DEBUG] 找到匹配的气泡，更新翻译")
                    child.translation = utterance.get('translation', '')
                    child.corrected_text = utterance.get('corrected', '')
                    print(f"[DEBUG] 气泡更新后: translation={repr(child.translation)}, corrected_text={repr(child.corrected_text)}")
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
        print(f"[DEBUG] _show_asr_utterances call #{self._asr_call_count}, utterances count: {len(utterances)}")
        chat_area = self.ids.chat_area
        print(f"[DEBUG] chat_area children before: {len(chat_area.children)}")
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
            print(f"[DEBUG] 处理utterance: definite={definite}, original_text={repr(original_text)}, corrected_text={repr(corrected_text)}, translation={repr(translation)}")
            if definite and original_text and key not in self.final_utterance_keys:
                utterance_id = id(utt)  # 使用utterance的id作为标识
                bubble = self.create_bubble(original_text, corrected_text, translation, timeout_tip, utterance_id)
                print(f"[DEBUG] 创建气泡: original_text={repr(bubble.original_text)}, corrected_text={repr(bubble.corrected_text)}, translation={repr(bubble.translation)}")
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
        print(f"[DEBUG] create_bubble输入: original_text={repr(original_text)}, corrected_text={repr(corrected_text)}, translation={repr(translation)}")
        cleaned_original = clean_text(original_text)
        cleaned_corrected = clean_text(corrected_text) if corrected_text else ''
        cleaned_translation = translation or ''
        print(f"[DEBUG] create_bubble清理后: cleaned_original={repr(cleaned_original)}, cleaned_corrected={repr(cleaned_corrected)}, cleaned_translation={repr(cleaned_translation)}")
        
        bubble = ChatBubble(
            original_text=cleaned_original, 
            corrected_text=cleaned_corrected,
            translation=cleaned_translation, 
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

    def on_original_text(self, instance, value):
        print(f"[DEBUG] ChatBubble original_text changed: {repr(value)}")
        # 确保文本是UTF-8编码
        if isinstance(value, str):
            try:
                # 尝试重新编码确保UTF-8
                value.encode('utf-8').decode('utf-8')
            except UnicodeError:
                print(f"[ERROR] Unicode encoding error in original_text: {repr(value)}")
        
    def on_corrected_text(self, instance, value):
        print(f"[DEBUG] ChatBubble corrected_text changed: {repr(value)}")
        # 确保文本是UTF-8编码
        if isinstance(value, str):
            try:
                value.encode('utf-8').decode('utf-8')
            except UnicodeError:
                print(f"[ERROR] Unicode encoding error in corrected_text: {repr(value)}")
        
    def on_translation(self, instance, value):
        print(f"[DEBUG] ChatBubble translation changed: {repr(value)}")

    def get_display_text(self):
        """获取显示文本，处理编码问题"""
        try:
            if self.corrected_text and self.corrected_text != self.original_text:
                display_text = self.corrected_text
            else:
                display_text = self.original_text
            
            # 确保文本是UTF-8编码
            if isinstance(display_text, str):
                # 重新编码确保UTF-8
                display_text.encode('utf-8').decode('utf-8')
                print(f"[DEBUG] get_display_text: {repr(display_text)}")
                return display_text
            else:
                return str(display_text) if display_text else ""
        except UnicodeError as e:
            print(f"[ERROR] Unicode error in get_display_text: {e}")
            return str(self.original_text) if self.original_text else ""

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
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # 使用模块级别的字体名
        self.font_name = font_name
        print(f"[DEBUG] TranslateChatApp font_name: {self.font_name}")
        
        # 测试字体渲染
        self.test_font_rendering()
        
        # 从配置中加载翻译设置
        self.load_translation_setting()
    
    def load_translation_setting(self):
        """从配置中加载翻译设置"""
        try:
            # 优先从环境变量加载
            translation_setting = os.environ.get('SHOW_TRANSLATION', 'True')
            self.show_translation = translation_setting.lower() in ('true', '1', 'yes')
            
            # 如果环境变量没有设置，尝试从加密存储加载
            if not os.environ.get('SHOW_TRANSLATION'):
                from config_manager import config_manager
                if config_manager.secure_storage:
                    encrypted_config = config_manager.secure_storage.load_config()
                    if encrypted_config and 'SHOW_TRANSLATION' in encrypted_config:
                        self.show_translation = encrypted_config['SHOW_TRANSLATION']
                        print(f"[配置] 从加密存储加载翻译设置: {self.show_translation}")
            
            print(f"[配置] 翻译设置已加载: {self.show_translation}")
        except Exception as e:
            print(f"[配置] 加载翻译设置失败: {e}")
            # 使用默认值
            self.show_translation = True
    def toggle_translation(self, value):
        self.show_translation = value
    
    def test_font_rendering(self):
        """测试字体渲染效果"""
        try:
            from utils.font_utils import test_font_rendering, get_font_info
            print("[字体] 开始字体渲染测试...")
            
            # 测试当前字体
            if test_font_rendering(self.font_name):
                print(f"[字体] 字体 {self.font_name} 渲染测试通过")
            else:
                print(f"[字体] 字体 {self.font_name} 渲染测试失败")
            
            # 获取字体信息
            font_info = get_font_info()
            print(f"[字体] 平台: {font_info['platform']}")
            print(f"[字体] 已注册字体: {font_info['registered_fonts']}")
            
        except Exception as e:
            print(f"[字体] 字体测试失败: {e}")
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