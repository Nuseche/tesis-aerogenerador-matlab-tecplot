"""Boundary and corruption checks for external SIMPACT binary histories."""
from pathlib import Path
import struct
import sys
import tempfile
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from audit_nonlinear_reference import read_history


def record(payload):
    marker = struct.pack('<I', len(payload))
    return marker+payload+marker


class HistoryReaderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)/'history.p11'
        self.header = record(b'T'+np.array([2, 6, 400019, 1], dtype='<i4').tobytes())
        self.first = np.arange(13, dtype='<f8')
        self.first[0] = 0
        self.second = self.first+10
        self.second[0] = .01
        self.valid = self.header+record(self.first.tobytes())+record(self.second.tobytes())

    def test_preserves_node_order_and_components(self):
        self.path.write_bytes(self.valid)
        nodes, time, values = read_history(self.path)
        np.testing.assert_array_equal(nodes, [400019, 1])
        np.testing.assert_allclose(time, [0, .01])
        np.testing.assert_array_equal(values[1, 1], self.second[7:])

    def test_rejects_truncation_and_bad_markers(self):
        for damaged in (self.valid[:-1], self.valid[:-4]+struct.pack('<I', 1)):
            with self.subTest(damaged=damaged[-5:]):
                self.path.write_bytes(damaged)
                with self.assertRaises(ValueError):
                    read_history(self.path)

    def test_rejects_time_reversal_and_nonfinite_data(self):
        for index, value in ((0, -.01), (8, np.nan)):
            data = self.second.copy()
            data[index] = value
            self.path.write_bytes(self.header+record(self.first.tobytes())+record(data.tobytes()))
            with self.assertRaises(ValueError):
                read_history(self.path)


if __name__ == '__main__':
    unittest.main()
