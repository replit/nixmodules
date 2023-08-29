module.exports = class TableDisplay {
  constructor({ wrapper, rows, columns, defaultBg, borderWidth, borderColor }) {
    this.rows = rows;
    this.columns = columns;
    this.defaultBg = defaultBg;
    this.borderWidth = borderWidth;
    this.borderColor = borderColor;

    this.pixmap = new Array(rows * columns).fill(defaultBg);
    this.clean = new Array(rows * columns).fill(false);

    const canvas = document.createElement("canvas");
    this.ctx = canvas.getContext("2d");
    wrapper.appendChild(canvas);

    const resize = () => {
      const width = wrapper.clientWidth;
      const height = wrapper.clientHeight;

      this.dim = Math.max(
        Math.floor(Math.min(width / columns, height / rows)),
        1 + borderWidth
      );

      canvas.width = this.dim * columns + borderWidth;
      canvas.height = this.dim * rows + borderWidth;
    };
    const getKey = (e) => e.key || String.fromCharCode(e.keyCode);
    this.keyQueue = [];
    wrapper.addEventListener("keypress", (e) => {
      this.keyQueue.push(getKey(e));
    });

    this.clickQueue = [];
    canvas.addEventListener("click", (e) => {
      const rect = e.target.getBoundingClientRect();
      const x = Math.floor((e.clientX - rect.x) / this.dim);
      const y = Math.floor((e.clientY - rect.y) / this.dim);
      this.clickQueue.push([
        Math.min(Math.max(x, 0), columns - 1),
        Math.min(Math.max(y, 0), rows - 1),
      ]);
    });

    resize();
    this.render();
  }

  queueRender = () => {
    if (this.pendingRender) return;
    this.pendingRender = true;

    requestAnimationFrame(() => {
      this.pendingRender = false;
      this.render();
    });
  };

  render = () => {
    const {
      pixmap,
      rows,
      columns,
      borderWidth,
      borderColor,
      defaultBg,
      clean,
      ctx,
      dim,
    } = this;

    if (borderWidth) {
      ctx.fillStyle = borderColor;
      for (let i = 0; i < columns + 1; i++) {
        ctx.fillRect(dim * i, 0, borderWidth, dim * rows);
      }
      for (let i = 0; i < rows + 1; i++) {
        ctx.fillRect(0, dim * i, dim * columns + borderWidth, borderWidth);
      }
    }

    let prev;
    for (let i = 0; i < pixmap.length; i++) {
      if (clean[i]) continue;

      if (pixmap[i] !== prev) {
        prev = ctx.fillStyle = pixmap[i];
      }

      const x = dim * (i % columns) + borderWidth;
      const y = dim * Math.floor(i / columns) + borderWidth;

      ctx.fillRect(x, y, dim - borderWidth, dim - borderWidth);
    }

    this.clean.fill(true);
  };

  plot = (x, y, color) => {
    if (!color) return;

    // Add # to hex colors (backwards compat)
    if (color.match(/^[0-9A-Fa-f]{6}$/)) {
      color = "#" + color;
    }

    if (typeof x !== "number") {
      x = parseFloat(x);
      if (isNaN(x)) return;
    }

    if (typeof y !== "number") {
      y = parseFloat(y);
      if (isNaN(y)) return;
    }

    x = Math.round(x);
    y = Math.round(y);

    if (x < 0 || y < 0) return;

    const i = y * this.rows + x;

    if (!this.pixmap[i]) return;
    if (this.pixmap[i] === color) return;

    this.clean[i] = false;
    this.pixmap[i] = color;
    this.queueRender();
  };

  color = (x, y) => this.pixmap[y * this.rows + x] || this.defaultBg;

  clear = () => {
    this.pixmap.fill(this.defaultBg);
    this.clean.fill(false);
    this.queueRender();
  };

  getChar = () => this.keyQueue.shift();
  getClick = () => this.clickQueue.shift();

  text = (x, y, text, size = 12, color = "black") => {
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "top";
    this.ctx.font = `${size}px monospace`;
    this.ctx.strokeStyle = color;
    this.ctx.fillStyle = color;
    this.ctx.fillText(text, this.dim * x, this.dim * y);
  };

  draw = (table) => {
    for (let i in table) {
      for (let j in table[i]) {
        this.plot(i, j, table[i][j]);
      }
    }
  };
};
