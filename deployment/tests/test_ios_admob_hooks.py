import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("ios_setup", Path(__file__).parents[1] / "ios/setup.py")
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class HookTests(unittest.TestCase):
    def test_plain_and_wrapped(self):
        for wrapped in (False, True):
            source = ""
            for hook in ("initialize", "deinitialize"):
                name = "godot_apple_embedded_plugins_" + hook
                if wrapped:
                    source += f"void {name}() {{{{ {name}_admob(); }}}}\n#define {name} {name}_admob\n"
                source += f"void {name}() {{ /* Firebase */ }}\n"
            result = setup.inject_plugin_hooks(source)
            for hook in ("initialize", "deinitialize"):
                self.assertEqual(result.count(f"    bisca_voice_{hook}();"), 1)
                if wrapped:
                    self.assertGreater(result.index(f"    bisca_voice_{hook}();"), result.index(f"#define godot_apple_embedded_plugins_{hook}"))
            self.assertEqual(setup.inject_plugin_hooks(result), result)

    def test_invalid_rejected(self):
        with self.assertRaises(ValueError):
            setup.inject_plugin_hooks("// unexpected export")


if __name__ == '__main__':
    unittest.main()
