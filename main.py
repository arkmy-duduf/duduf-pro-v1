import tkinter as tk
from tkinter import ttk, messagebox
import json
import math
import ttkbootstrap as tb  # pip install ttkbootstrap
from PIL import Image, ImageTk  # pip install pillow


# ------------------ Utilitaires ------------------
def parse_float(value, default=0.0):
    try:
        return float(str(value).strip().replace(",", "."))
    except Exception:
        return default

def make_entry(parent, variable, row, col, **grid_kwargs):
    """Entry auto-nettoyant : efface le contenu au focus."""
    entry = ttk.Entry(parent, textvariable=variable)
    entry.grid(row=row, column=col, sticky="ew", pady=5, **grid_kwargs)
    entry.bind("<FocusIn>", lambda e: e.widget.delete(0, tk.END))
    return entry


# ------------------ Aires profils libres (en mm²) ------------------
def area_tube_rond(d_ext, e):
    r_ext = d_ext / 2.0
    r_int = max(r_ext - e, 0)
    return math.pi * (r_ext**2 - r_int**2)

def area_tube_carre(c_ext, e):
    c_int = max(c_ext - 2*e, 0)
    return c_ext**2 - c_int**2

def area_tube_rect(l_ext, h_ext, e):
    l_int = max(l_ext - 2*e, 0)
    h_int = max(h_ext - 2*e, 0)
    return (l_ext * h_ext) - (l_int * h_int)

def area_rond_plein(d):
    r = d / 2.0
    return math.pi * r**2

def area_carre_plein(c):
    return c**2

def area_rectangle_plein(l, h):
    return l * h

def area_plat(l, e):
    return l * e

def area_corniere(a1, a2, e):
    # Deux ailes moins le carré du noyau au coin
    return (a1 * e) + (a2 * e) - (e * e)


# ------------------ Application ------------------
class App(tb.Window):
    LOGO_PATH = "duduf_occas_logo.png"  # adapte si ton fichier a un autre nom

    def __init__(self):
        super().__init__(themename="superhero")
        self.title("Duduf occas")
        self.geometry("480x720")

        # ----- Header + logo (centré) -----
        self.header = ttk.Frame(self)
        self.header.pack(side="top", fill="x", pady=(10, 0))

        self.logo_label = ttk.Label(self.header)
        self.logo_label.pack(anchor="center")

        self._load_logo()   # charge l'image
        self.bind("<Configure>", self._on_resize)  # redimensionnement auto

        # Charger données
        with open("profiles.json", "r", encoding="utf-8") as f:
            data = json.load(f)
        self.DENSITIES = data["densities"]
        self.PROFILS_LIBRES = data["profils_libres"]
        self.PROFILES = {k: v for k, v in data.items() if k not in ["densities", "profils_libres"]}

        with open("prices.json", "r", encoding="utf-8") as f:
            self.PRICES = json.load(f)

        # Variables UI
        self.matiere = tk.StringVar(value="acier")
        self.groupe = tk.StringVar(value="HEA")
        self.profil = tk.StringVar(value="")
        self.longueur = tk.StringVar(value="")
        self.dim1 = tk.StringVar(value="")
        self.dim2 = tk.StringVar(value=""
        )
        self.epaisseur = tk.StringVar(value="")

        self.result_poids = tk.StringVar(value="Poids : —")
        self.result_prix = tk.StringVar(value="Prix : —")

        self.price_matiere = tk.StringVar(value="acier")
        self.price_value = tk.StringVar(value=str(self.PRICES.get("acier", 0.0)))

        # Case à cocher "Je connais le patron"
        self.patron_var = tk.BooleanVar(value=False)

        # Construire l'UI
        self._build_ui()

    # --------------- LOGO ---------------
    def _load_logo(self):
        """Charge le logo d'origine et pousse une première version redimensionnée."""
        try:
            self._logo_src = Image.open(self.LOGO_PATH).convert("RGBA")
            self._push_logo(target_w=200)  # première taille
        except Exception as e:
            print("Impossible de charger le logo :", e)

    def _push_logo(self, target_w: int):
        """Redimensionne le logo à la largeur demandée en gardant le ratio."""
        if not hasattr(self, "_logo_src"):
            return
        target_w = max(120, min(target_w, 420))  # bornes raisonnables
        w, h = self._logo_src.size
        new_h = int(h * (target_w / w))
        img = self._logo_src.resize((target_w, new_h), Image.Resampling.LANCZOS)
        self._logo_photo = ImageTk.PhotoImage(img)  # garde une ref pour éviter le GC
        self.logo_label.configure(image=self._logo_photo)

    def _on_resize(self, event=None):
        """Adapte la taille du logo à la largeur de la fenêtre."""
        try:
            # 35% de la largeur utile, bornée par _push_logo
            target = int(self.winfo_width() * 0.35)
            self._push_logo(target)
        except Exception:
            pass

    # --------------- Callbacks ---------------
    def on_groupe_changed(self, event=None):
        grp = self.groupe.get()
        if grp == "Profils libres":
            self.cb_profil["values"] = self.PROFILS_LIBRES
            self.profil.set(self.PROFILS_LIBRES[0])
            self.set_dims_state(enabled=True)
            self.update_dim_labels()
        else:
            self.cb_profil["values"] = list(self.PROFILES[grp].keys())
            self.profil.set("")
            self.set_dims_state(enabled=False)
            self.show_all_dims()
            self.lbl_dim1.config(text="Dim 1 (mm) :")
            self.lbl_dim2.config(text="Dim 2 (mm) :")
            self.lbl_ep.config(text="Épaisseur (mm) :")

    def update_dim_labels(self, event=None):
        if self.groupe.get() != "Profils libres":
            return
        typ = self.profil.get()
        self.show_all_dims()
        if typ == "Tube rond":
            self.lbl_dim1.config(text="Diamètre ext (mm) :")
            self.hide_dim2()
            self.lbl_ep.config(text="Épaisseur (mm) :")
        elif typ == "Tube carré":
            self.lbl_dim1.config(text="Côté ext (mm) :")
            self.hide_dim2()
            self.lbl_ep.config(text="Épaisseur (mm) :")
        elif typ == "Tube rectangle":
            self.lbl_dim1.config(text="Largeur ext (mm) :")
            self.lbl_dim2.config(text="Hauteur ext (mm) :")
            self.lbl_ep.config(text="Épaisseur (mm) :")
        elif typ == "Rond plein":
            self.lbl_dim1.config(text="Diamètre (mm) :")
            self.hide_dim2()
            self.hide_ep()
        elif typ == "Carré plein":
            self.lbl_dim1.config(text="Côté (mm) :")
            self.hide_dim2()
            self.hide_ep()
        elif typ == "Rectangle plein":
            self.lbl_dim1.config(text="Largeur (mm) :")
            self.lbl_dim2.config(text="Hauteur (mm) :")
            self.hide_ep()
        elif typ == "Plat":
            self.lbl_dim1.config(text="Largeur (mm) :")
            self.hide_dim2()
            self.lbl_ep.config(text="Épaisseur (mm) :")
        elif typ == "Cornière":
            self.lbl_dim1.config(text="Aile 1 (mm) :")
            self.lbl_dim2.config(text="Aile 2 (mm) :")
            self.lbl_ep.config(text="Épaisseur (mm) :")

    def set_dims_state(self, enabled: bool):
        state = "normal" if enabled else "disabled"
        for w in (self.ent_dim1, self.ent_dim2, self.ent_ep):
            w.configure(state=state)

    def hide_dim2(self):
        self.lbl_dim2.grid_remove()
        self.ent_dim2.grid_remove()

    def hide_ep(self):
        self.lbl_ep.grid_remove()
        self.ent_ep.grid_remove()

    def show_all_dims(self):
        self.lbl_dim2.grid()
        self.ent_dim2.grid()
        self.lbl_ep.grid()
        self.ent_ep.grid()

    def on_price_matiere_changed(self, event=None):
        mat = self.price_matiere.get()
        self.price_value.set(str(self.PRICES.get(mat, 0.0)))

    # --------------- UI ---------------
    def _build_ui(self):
        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True, padx=10, pady=10)

        tab_calc = ttk.Frame(notebook)
        notebook.add(tab_calc, text="⚖️  Calcul")

        frm = ttk.Frame(tab_calc, padding=16)
        frm.pack(fill="both", expand=True)
        frm.columnconfigure(1, weight=1)

        ttk.Label(frm, text="Matière :", font=("Segoe UI", 11)).grid(row=0, column=0, sticky="w", pady=5)
        cb_mat = ttk.Combobox(frm, textvariable=self.matiere, values=list(self.DENSITIES.keys()), state="readonly")
        cb_mat.grid(row=0, column=1, sticky="ew", pady=5)

        ttk.Label(frm, text="Groupe :", font=("Segoe UI", 11)).grid(row=1, column=0, sticky="w", pady=5)
        values_groupes = list(self.PROFILES.keys()) + ["Profils libres"]
        cb_grp = ttk.Combobox(frm, textvariable=self.groupe, values=values_groupes, state="readonly")
        cb_grp.grid(row=1, column=1, sticky="ew", pady=5)
        cb_grp.bind("<<ComboboxSelected>>", self.on_groupe_changed)

        ttk.Label(frm, text="Profil / Type :", font=("Segoe UI", 11)).grid(row=2, column=0, sticky="w", pady=5)
        self.cb_profil = ttk.Combobox(frm, textvariable=self.profil, state="readonly")
        self.cb_profil.grid(row=2, column=1, sticky="ew", pady=5)
        self.cb_profil.bind("<<ComboboxSelected>>", self.update_dim_labels)

        ttk.Label(frm, text="Longueur (m) :", font=("Segoe UI", 11)).grid(row=3, column=0, sticky="w", pady=5)
        self.ent_longueur = make_entry(frm, self.longueur, 3, 1)

        self.lbl_dim1 = ttk.Label(frm, text="Dim 1 (mm) :", font=("Segoe UI", 11))
        self.lbl_dim1.grid(row=4, column=0, sticky="w", pady=5)
        self.ent_dim1 = make_entry(frm, self.dim1, 4, 1)

        self.lbl_dim2 = ttk.Label(frm, text="Dim 2 (mm) :", font=("Segoe UI", 11))
        self.lbl_dim2.grid(row=5, column=0, sticky="w", pady=5)
        self.ent_dim2 = make_entry(frm, self.dim2, 5, 1)

        self.lbl_ep = ttk.Label(frm, text="Épaisseur (mm) :", font=("Segoe UI", 11))
        self.lbl_ep.grid(row=6, column=0, sticky="w", pady=5)
        self.ent_ep = make_entry(frm, self.epaisseur, 6, 1)

        # --- CASE PATRON ---
        chk_patron = ttk.Checkbutton(frm, text="Je connais le patron", variable=self.patron_var)
        chk_patron.grid(row=7, column=0, columnspan=2, pady=5)

        btn = tb.Button(frm, text="Calculer", bootstyle="success", command=self.calc_weight_price)
        btn.grid(row=8, column=0, columnspan=2, pady=14, ipadx=10, ipady=6)

        box = tb.Frame(frm, bootstyle="secondary", padding=14)
        box.grid(row=9, column=0, columnspan=2, sticky="ew", pady=10)
        ttk.Label(box, textvariable=self.result_poids, font=("Segoe UI", 12, "bold")).pack(pady=4)
        ttk.Label(box, textvariable=self.result_prix, font=("Segoe UI", 12, "bold")).pack(pady=4)

        # Onglet Prix
        tab_price = ttk.Frame(notebook)
        notebook.add(tab_price, text="💰  Prix matières")
        frm2 = ttk.Frame(tab_price, padding=16)
        frm2.pack(fill="both", expand=True)
        frm2.columnconfigure(1, weight=1)

        ttk.Label(frm2, text="Matière :", font=("Segoe UI", 11)).grid(row=0, column=0, sticky="w", pady=5)
        cb_price = ttk.Combobox(frm2, textvariable=self.price_matiere, values=list(self.PRICES.keys()), state="readonly")
        cb_price.grid(row=0, column=1, sticky="ew", pady=5)
        cb_price.bind("<<ComboboxSelected>>", self.on_price_matiere_changed)

        ttk.Label(frm2, text="Prix €/kg :", font=("Segoe UI", 11)).grid(row=1, column=0, sticky="w", pady=5)
        self.ent_price = make_entry(frm2, self.price_value, 1, 1)

        tb.Button(frm2, text="Sauvegarder", bootstyle="primary", command=self.save_price)\
          .grid(row=2, column=0, columnspan=2, pady=14, ipadx=10, ipady=6)

        self.on_groupe_changed()

    # --------------- Calcul ---------------
    def calc_weight_price(self):
        mat = self.matiere.get()
        dens = self.DENSITIES.get(mat, 7850)
        price_kg = parse_float(self.PRICES.get(mat, 0.0))
        L_m = parse_float(self.longueur.get(), 0.0)

        if L_m <= 0:
            messagebox.showerror("Erreur", "Merci de saisir une longueur (m) > 0.")
            return

        grp = self.groupe.get()
        prof = self.profil.get()

        try:
            if grp == "Profils libres":
                typ = prof
                d1 = parse_float(self.dim1.get(), 0.0)
                d2 = parse_float(self.dim2.get(), 0.0)
                e  = parse_float(self.epaisseur.get(), 0.0)

                if typ in ("Rond plein", "Carré plein", "Tube rond", "Tube carré", "Plat") and d1 <= 0:
                    messagebox.showerror("Erreur", "Dim 1 doit être > 0.")
                    return
                if typ in ("Tube rond", "Tube carré", "Tube rectangle", "Cornière") and e <= 0:
                    messagebox.showerror("Erreur", "Épaisseur doit être > 0.")
                    return
                if typ in ("Tube rectangle", "Rectangle plein", "Cornière") and d2 <= 0:
                    messagebox.showerror("Erreur", "Dim 2 doit être > 0.")
                    return

                if typ == "Tube rond":
                    area_mm2 = area_tube_rond(d1, e)
                elif typ == "Tube carré":
                    area_mm2 = area_tube_carre(d1, e)
                elif typ == "Tube rectangle":
                    area_mm2 = area_tube_rect(d1, d2, e)
                elif typ == "Rond plein":
                    area_mm2 = area_rond_plein(d1)
                elif typ == "Carré plein":
                    area_mm2 = area_carre_plein(d1)
                elif typ == "Rectangle plein":
                    area_mm2 = area_rectangle_plein(d1, d2)
                elif typ == "Plat":
                    area_mm2 = area_plat(d1, e)
                elif typ == "Cornière":
                    area_mm2 = area_corniere(d1, d2, e)
                else:
                    messagebox.showerror("Erreur", "Type de profil libre inconnu.")
                    return

                vol_mm3 = area_mm2 * (L_m * 1000.0)
                vol_m3 = vol_mm3 * 1e-9
                poids = vol_m3 * dens
            else:
                if not prof:
                    messagebox.showerror("Erreur", "Choisis un profil dans la liste.")
                    return
                try:
                    kg_m = self.PROFILES[grp][prof]["kg_m"]
                except KeyError:
                    messagebox.showerror("Erreur", "Profil introuvable dans ce groupe.")
                    return
                poids = kg_m * L_m * (dens / self.DENSITIES["acier"])

            prix = poids * price_kg
            if getattr(self, "patron_var", False) and self.patron_var.get():
                prix *= 1.25

            self.result_poids.set(f"Poids : {poids:.2f} kg")
            self.result_prix.set(f"Prix : {prix:.2f} €")

        except Exception as e:
            messagebox.showerror("Erreur", f"Problème de calcul : {e}")

    # --------------- Sauvegarde prix ---------------
    def save_price(self):
        mat = self.price_matiere.get()
        try:
            val = parse_float(self.price_value.get(), None)
            if val is None or val < 0:
                messagebox.showerror("Erreur", "Prix €/kg invalide.")
                return
            self.PRICES[mat] = val
            with open("prices.json", "w", encoding="utf-8") as f:
                json.dump(self.PRICES, f, indent=2, ensure_ascii=False)
            messagebox.showinfo("Sauvegarde", f"Nouveau prix enregistré : {mat} = {val:.2f} €/kg")
        except Exception as e:
            messagebox.showerror("Erreur", f"Impossible d'enregistrer : {e}")


# ------------------ Run ------------------
if __name__ == "__main__":
    app = App()
    app.mainloop()
