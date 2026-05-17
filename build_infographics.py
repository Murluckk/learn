"""
Инфографика для отчёта по депропанизатору.
Генерирует 3 файла-PNG, которые потом вставляются в .docx.
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.ticker import MultipleLocator

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.labelsize": 11,
    "axes.spines.top": False,
    "axes.spines.right": False,
})

C_RANGE = "#cfe8ff"      # светло-голубой — литературный диапазон
C_RANGE_E = "#3a82c4"    # тёмная окантовка
C_VAL_OK = "#2ca02c"     # зелёный — в диапазоне
C_VAL_BAD = "#d62728"    # красный — не в диапазоне
C_VAL_EDGE = "#ff7f0e"   # оранжевый — на границе
C_BAR_FACT = "#1f77b4"
C_GOST_PT = "#ff7f0e"
C_GOST_PA = "#d62728"


# =========================================================================
# Рисунок 1: Сопоставление технологических параметров с литературой
# =========================================================================
def chart_tech_vs_lit(out="infographic_tech_vs_lit.png"):
    """Слева — название параметра; справа — литер. диапазон полосой и наша
    точка-маркер. Нормализация выполняется в условные единицы (0..1)."""
    data = [
        # name, our, lo, hi, ok flag
        ("Давление верха, МПа",                  1.925, 1.4, 2.0,  "ok"),
        ("Температура верха, °C",                84.2, 40.0, 95.0, "ok"),
        ("Температура низа, °C",                 163.8, 110.0, 180.0, "ok"),
        ("Перепад давления, кПа",                30,   20,  40,   "ok"),
        ("Число теоретических ступеней",         24,   20,  40,   "ok"),
        ("Извлечение пропана в дистиллят, %",    99.1, 95,  99,   "ok"),
        ("Проскок пропана в куб, мол. %",        0.78, 0,   2,    "ok"),
        ("Чистота пропана (мол. %)",             76.8, 92,  98,   "bad"),
        ("Чистота пропана (% мас.)",             70.1, 75,  85,   "bad"),
        ("Расщепление i-C4 → куб, %",            47.6, 85,  95,   "bad"),
    ]

    fig, ax = plt.subplots(figsize=(11, 6.8), dpi=180)
    y_positions = list(range(len(data)))[::-1]

    for y, (name, val, lo, hi, flag) in zip(y_positions, data):
        # Объединённое поле «литер. диапазон» — нормируем для каждой строки
        # в её собственный масштаб 0..1, поэтому делаем так:
        # выстраиваем единую относительную ось 0..1 на основе lo, hi, val.
        # Для наглядности отступ +/- 30% от диапазона.
        span = max(hi - lo, 0.001)
        pad = span * 0.4
        xmin = min(lo, val) - pad
        xmax = max(hi, val) + pad
        # Перевод в относительные координаты на оси (диапазон 0..1)
        def norm(x):
            return (x - xmin) / (xmax - xmin)
        # Полоса литературного диапазона
        ax.barh(y, norm(hi) - norm(lo), left=norm(lo),
                height=0.55, color=C_RANGE, edgecolor=C_RANGE_E, linewidth=1.2)
        # Наша точка
        col = {"ok": C_VAL_OK, "edge": C_VAL_EDGE, "bad": C_VAL_BAD}[flag]
        ax.plot(norm(val), y, marker="D", markersize=11, color=col,
                markeredgecolor="black", markeredgewidth=0.8, zorder=5)
        # Подписи концов диапазона
        ax.annotate(f"{lo:g}", xy=(norm(lo), y), xytext=(-3, 0),
                    textcoords="offset points", va="center", ha="right",
                    fontsize=9, color="#444")
        ax.annotate(f"{hi:g}", xy=(norm(hi), y), xytext=(3, 0),
                    textcoords="offset points", va="center", ha="left",
                    fontsize=9, color="#444")
        # Подпись нашей величины
        offset_y = 0.32 if flag != "bad" else -0.35
        ax.annotate(f"{val:g}", xy=(norm(val), y),
                    xytext=(0, 14 if offset_y > 0 else -16),
                    textcoords="offset points",
                    ha="center", va="center", fontsize=10,
                    color=col, fontweight="bold")

    ax.set_yticks(y_positions)
    ax.set_yticklabels([d[0] for d in data], fontsize=10)
    ax.set_xticks([])
    ax.set_xlim(0, 1)
    ax.set_xlabel("Относительная шкала параметра (литературный диапазон)",
                  fontsize=10, color="#444")
    ax.set_title("Сопоставление расчётных параметров депропанизатора\n"
                 "с литературными данными [1, 3, 7, 11]",
                 fontsize=13, fontweight="bold")

    # Легенда
    legend = [
        mpatches.Patch(color=C_RANGE, label="Литературный диапазон"),
        plt.Line2D([0], [0], marker="D", color="w", markerfacecolor=C_VAL_OK,
                   markeredgecolor="black", markersize=10, label="Расчёт — в диапазоне"),
        plt.Line2D([0], [0], marker="D", color="w", markerfacecolor=C_VAL_BAD,
                   markeredgecolor="black", markersize=10,
                   label="Расчёт — вне диапазона"),
    ]
    ax.legend(handles=legend, loc="lower right",
              bbox_to_anchor=(1.0, -0.18), frameon=False, fontsize=10, ncol=3)
    ax.grid(False)

    plt.tight_layout()
    plt.savefig(out, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close()
    print("OK:", out)


# =========================================================================
# Рисунок 2: Состав дистиллята vs ГОСТ Р 52087-2018
# =========================================================================
def chart_composition_vs_gost(out="infographic_composition_vs_gost.png"):
    components = ["Пропан\n(C3)", "Бутаны\n(i+n-C4)", "C5 и тяжелее",
                  "Этан (C2)"]
    factual = [70.07, 18.48, 10.55, 0.91]
    pt_min = [75, None, None, None]
    pt_max = [None, 20, 1.0, 4]
    pa_min = [85, None, None, None]
    pa_max = [None, None, 0.7, 4]

    fig, ax = plt.subplots(figsize=(11, 6), dpi=180)

    x = list(range(len(components)))
    width = 0.55
    bars = ax.bar(x, factual, width, color=C_BAR_FACT,
                  edgecolor="black", linewidth=0.6,
                  label="Расчёт (дистиллят)", zorder=3)

    # Подписи столбцов
    for xi, val in zip(x, factual):
        ax.text(xi, val + 1, f"{val:.2f} %", ha="center", va="bottom",
                fontsize=10, fontweight="bold", color=C_BAR_FACT)

    # Линии пороговых значений
    y_max = 90
    for xi, (mn, mx) in enumerate(zip(pt_min, pt_max)):
        if mn is not None:
            ax.hlines(mn, xi - width / 2 - 0.05, xi + width / 2 + 0.05,
                      colors=C_GOST_PT, linestyles="--", linewidth=2, zorder=4)
            ax.text(xi + width / 2 + 0.08, mn, f"ПТ ≥ {mn} %",
                    va="center", color=C_GOST_PT, fontsize=9)
        if mx is not None:
            ax.hlines(mx, xi - width / 2 - 0.05, xi + width / 2 + 0.05,
                      colors=C_GOST_PT, linestyles="--", linewidth=2, zorder=4)
            ax.text(xi + width / 2 + 0.08, mx, f"ПТ ≤ {mx} %",
                    va="center", color=C_GOST_PT, fontsize=9)
    for xi, (mn, mx) in enumerate(zip(pa_min, pa_max)):
        if mn is not None:
            ax.hlines(mn, xi - width / 2 - 0.05, xi + width / 2 + 0.05,
                      colors=C_GOST_PA, linestyles=":", linewidth=2, zorder=4)
            ax.text(xi + width / 2 + 0.08, mn, f"ПА ≥ {mn} %",
                    va="center", color=C_GOST_PA, fontsize=9)
        if mx is not None and mx != pt_max[xi]:
            ax.hlines(mx, xi - width / 2 - 0.05, xi + width / 2 + 0.05,
                      colors=C_GOST_PA, linestyles=":", linewidth=2, zorder=4)
            ax.text(xi + width / 2 + 0.08, mx, f"ПА ≤ {mx} %",
                    va="center", color=C_GOST_PA, fontsize=9)

    ax.set_xticks(x)
    ax.set_xticklabels(components, fontsize=11)
    ax.set_ylabel("Массовая доля, %", fontsize=11)
    ax.set_ylim(0, y_max)
    ax.yaxis.set_major_locator(MultipleLocator(10))
    ax.grid(axis="y", linestyle=":", alpha=0.5, zorder=0)
    ax.set_title("Состав дистиллята колонны (поток Propane) в сопоставлении\n"
                 "с требованиями ГОСТ Р 52087-2018 [12]",
                 fontsize=13, fontweight="bold")

    legend = [
        mpatches.Patch(color=C_BAR_FACT, label="Расчёт (дистиллят, % мас.)"),
        plt.Line2D([0], [0], color=C_GOST_PT, linestyle="--", linewidth=2,
                   label="ГОСТ Р 52087-2018, марка ПТ (пропан техн.)"),
        plt.Line2D([0], [0], color=C_GOST_PA, linestyle=":", linewidth=2,
                   label="ГОСТ Р 52087-2018, марка ПА (пропан авт.)"),
    ]
    ax.legend(handles=legend, loc="upper right", frameon=False, fontsize=10)

    plt.tight_layout()
    plt.savefig(out, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close()
    print("OK:", out)


# =========================================================================
# Рисунок 3: Распределение каждого компонента между верхом и низом
# =========================================================================
def chart_component_split(out="infographic_component_split.png"):
    """Stacked bar: для каждого компонента — % уходящий в дистиллят (верх) и
    в кубовый продукт (низ). Лёгкие должны быть ~100% наверх, тяжёлые ~100%
    вниз; промежуточные показывают «остроту» разделения."""
    # Считаем на основе расходов и мольных долей
    F = 1836; D = 979.3; B = 856.5
    comp = [
        ("Этан C2",      0.0078, 0.0146, 0.0000),
        ("Пропан C3",    0.4134, 0.7681, 0.0078),
        ("i-Бутан",      0.0708, 0.0696, 0.0722),
        ("n-Бутан",      0.1226, 0.0841, 0.1666),
        ("i-Пентан",     0.0518, 0.0168, 0.0919),
        ("n-Пентан",     0.0415, 0.0113, 0.0762),
        ("n-Гексан C6",  0.2920, 0.0356, 0.5853),
    ]
    names, top_pct, bot_pct = [], [], []
    for n, xf, xd, xb in comp:
        feed_kmol = F * xf
        dist_kmol = D * xd
        btm_kmol = B * xb
        # нормируем (могут быть округления)
        total = dist_kmol + btm_kmol
        top_pct.append(100 * dist_kmol / total)
        bot_pct.append(100 * btm_kmol / total)
        names.append(n)

    fig, ax = plt.subplots(figsize=(11, 5.5), dpi=180)
    x = list(range(len(names)))
    width = 0.55
    b1 = ax.bar(x, top_pct, width, color="#4c95d4", edgecolor="black",
                linewidth=0.5, label="В дистиллят (Propane)", zorder=3)
    b2 = ax.bar(x, bot_pct, width, bottom=top_pct, color="#f0a050",
                edgecolor="black", linewidth=0.5,
                label="В кубовый продукт (C4+)", zorder=3)

    for xi, (t, bt) in enumerate(zip(top_pct, bot_pct)):
        if t > 6:
            ax.text(xi, t / 2, f"{t:.1f} %", ha="center", va="center",
                    fontsize=10, color="white", fontweight="bold")
        if bt > 6:
            ax.text(xi, t + bt / 2, f"{bt:.1f} %", ha="center", va="center",
                    fontsize=10, color="white", fontweight="bold")

    # Идеальная «острая» граница между лёгким (C3) и тяжёлым (i-C4)
    # отмечается вертикальной линией:
    ax.axvline(1.5, color="#444", linestyle=":", linewidth=1.5)
    ax.text(1.5, 105, "лёгкий ключ\n(C3) │ тяжёлый ключ (i-C4)",
            ha="center", va="bottom", fontsize=9, color="#444")

    ax.set_xticks(x)
    ax.set_xticklabels(names, fontsize=11)
    ax.set_ylabel("Доля компонента в продуктовом потоке, %", fontsize=11)
    ax.set_ylim(0, 115)
    ax.set_yticks([0, 25, 50, 75, 100])
    ax.grid(axis="y", linestyle=":", alpha=0.5, zorder=0)
    ax.set_title("Распределение компонентов питания между дистиллятом "
                 "и кубовым продуктом\n"
                 "(чем «острее» граница у пары C3/i-C4 — тем выше чистота "
                 "пропана)",
                 fontsize=13, fontweight="bold")
    ax.legend(loc="lower right", frameon=False, fontsize=10)

    plt.tight_layout()
    plt.savefig(out, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close()
    print("OK:", out)


if __name__ == "__main__":
    chart_tech_vs_lit()
    chart_composition_vs_gost()
    chart_component_split()
