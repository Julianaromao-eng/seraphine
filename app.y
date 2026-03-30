import streamlit as st
import pandas as pd
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import io

# Configuração da Página
st.set_page_config(page_title="Seraphine Sistema", layout="centered")

st.title("👠 Seraphine - Sistema de Pedidos")

# Inicializar o estado da sessão para armazenar os itens
if 'pedido_itens' not in st.session_state:
    st.session_state.pedido_itens = []

# --- DADOS DO CLIENTE ---
with st.expander("👤 Dados do Cliente", expanded=True):
    nome_cliente = st.text_input("Nome do Cliente")

# --- ADICIONAR PRODUTO ---
with st.form("form_item"):
    st.subheader("📦 Adicionar Produto")
    ref = st.text_input("Referência (ex: REF001)").upper()
    desconto = st.number_input("Desconto (%)", min_value=0, max_value=100, value=0)
    
    st.write("**Grade de Numeração (33 ao 40)**")
    cols = st.columns(4)
    numeros = ["33", "34", "35", "36", "37", "38", "39", "40"]
    grade_input = {}
    
    for i, num in enumerate(numeros):
        with cols[i % 4]:
            grade_input[num] = st.number_input(f"Tam {num}", min_value=0, step=1, key=f"n{num}")
    
    submit = st.form_submit_button("Adicionar ao Pedido")

    if submit:
        if not ref:
            st.error("Por favor, insira a Referência.")
        else:
            total_pares = sum(grade_input.values())
            if total_pares == 0:
                st.warning("Insira a quantidade na grade.")
            else:
                # Simulação de preço (Pode conectar ao seu banco de dados aqui)
                preco_base = 100.0  
                preco_final = preco_base * (1 - desconto/100)
                
                grade_texto = " ".join([f"{k}:{v}" for k, v in grade_input.items() if v > 0])
                
                st.session_state.pedido_itens.append({
                    "REF": ref,
                    "Grade": grade_texto,
                    "Qtd": total_pares,
                    "Unit": preco_final,
                    "Subtotal": preco_final * total_pares
                })
                st.success("Item adicionado!")

# --- TABELA DE PEDIDOS ---
if st.session_state.pedido_itens:
    st.subheader("🛒 Itens do Pedido")
    df = pd.DataFrame(st.session_state.pedido_itens)
    st.table(df)
    
    total_pedido = df["Subtotal"].sum()
    st.metric("Total do Pedido", f"R$ {total_pedido:.2f}")

    # --- GERAR PDF ---
    if st.button("📄 Gerar PDF do Pedido"):
        buffer = io.BytesIO()
        c = canvas.Canvas(buffer, pagesize=A4)
        c.drawString(50, 800, f"SERAPHINE - PEDIDO DE VENDA")
        c.drawString(50, 780, f"Cliente: {nome_cliente}")
        c.drawString(50, 760, f"Data: {datetime.now().strftime('%d/%m/%Y')}")
        
        y = 730
        for item in st.session_state.pedido_itens:
            c.drawString(50, y, f"{item['REF']} - {item['Grade']} - Qtd: {item['Qtd']} - Total: R${item['Subtotal']:.2f}")
            y -= 20
        
        c.drawString(50, y-20, f"TOTAL GERAL: R$ {total_pedido:.2f}")
        c.save()
        
        st.download_button(
            label="⬇️ Baixar PDF",
            data=buffer.getvalue(),
            file_name=f"Pedido_{nome_cliente}.pdf",
            mime="application/pdf"
        )

if st.button("🗑️ Limpar Pedido"):
    st.session_state.pedido_itens = []
    st.rerun()