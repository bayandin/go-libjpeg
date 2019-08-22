// +build gofuzz

package jpeg

import (
	"bytes"
	"fmt"
	"reflect"
)

func Fuzz(data []byte) int {
	cfg, err := DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return 0
	}
	if cfg.Width*cfg.Height > 1e6 {
		return 0
	}

	img, err := Decode(bytes.NewReader(data), &DecoderOptions{})
	if err != nil {
		return 0
	}

	for _, q := range []int{0, 80, 100} {
		var w bytes.Buffer
		err = Encode(&w, img, &EncoderOptions{Quality: q})
		if err != nil {
			panic(fmt.Sprintf("decode-encode failed (Quality=%d):\n%v", q, err))
		}

		img1, err := Decode(&w, &DecoderOptions{})
		if err != nil {
			panic(fmt.Sprintf("decode-encode-decode failed (Quality=%d):\n%v", q, err))
		}
		if !reflect.DeepEqual(img.Bounds(), img1.Bounds()) {
			panic(fmt.Sprintf("bounds changed (Quality=%d)", q))
		}
	}

	return 1
}
