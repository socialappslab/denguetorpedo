# encoding: UTF-8

#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3


Neighborhood.find_or_create_by_name("Maré")
Neighborhood.find_or_create_by_name("Vila Autódromo")

puts "\n" * 3
puts "[ok] Done seeding neighborhoods..."
puts "-" * 80

#------------------------------------------------------------------------------
# Elimination types and methods

puts "-" * 80
puts "[!] Seeding elimination types and methods..."
puts "\n" * 3

e1 = EliminationType.find_or_create_by_name("Pratinho de planta")
m1 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e1.id, "Elimine fazendo furos no pratinho", 200)
m2 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e1.id, "Prato removido (ou seja, não mais utilizado)", 200)
m3 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e1.id, "Coloque areia", 100)
m4 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e1.id, "Retire a água e esfregue para remover possíveis ovos (uma vez por semana).", 50)

e2 = EliminationType.find_or_create_by_name("Pneu")
m5 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e2.id, "Desfaça-se do pneu (entregue ao serviço de limpeza)", 50)
m6 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e2.id, "Arranje um uso alternativo para o pneu: preencha com terra e faça uma horta; preencha com areia, terra e cimento e utilize como degrau.", 450)
m7 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e2.id, "Transferir o pneu sem água para um local coberto e seco.", 100)
m8 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e2.id, "Cubra o pneu com algo que não se transforme em um foco potencial do mosquito.", 100)

e3 = EliminationType.find_or_create_by_name("Lixo (recipientes inutilizados)")
m9 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e3.id, "Jogá-los em uma lixeira bem tampada.", 0)
m10 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e3.id, "Organize um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", 450)
m11 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e3.id, "Participe de um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", 350)

e4  = EliminationType.find_or_create_by_name("Pequenos Recipientes utilizáveis Garrafas de vidro, vasos, baldes, tigela de água de cachorro")
m12 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e4.id, "Remova a água e esfregue uma vez por semana; ou, no caso de bebedouros de animais e aves, trocar a água e limpar diariamente.", 50)
m13 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e4.id, "Elimine fazendo furos no pratinho", 200)

e5  = EliminationType.find_or_create_by_name("Grandes Recipientes Utilizáveis Tonéis, outras depósitos de água, pias, galões d’água.")
m14 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e5.id, "Cobrir a caixa d’água", 450)
m15 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e5.id, "Vedar adequadamente com tapa e ou capa apropriada", 200)
m16 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e5.id, "Outros recipientes: esfregue, seque, cubra ou sele.", 350)

e6 = EliminationType.find_or_create_by_name("Calha")

e7  = EliminationType.find_or_create_by_name("Registros abertos")
m17 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e7.id, "Sele com cobertura impermeável para prevenir a penetração da água e ainda ter acesso ao registro.", 300)
m18 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e7.id, "Preencha com areia ou terra e mude o acesso à válvula.", 300)
m19 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e7.id, "Vedar.", 300)

e8  = EliminationType.find_or_create_by_name("Laje e terraços com água")
m19 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e8.id, "Limpá-las.", 300)

e9  = EliminationType.find_or_create_by_name("Piscinas")
m20 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e9.id, "Piscinas em uso: esfregue e limpe uma vez por semana", 350)
m21 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e9.id, "Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde.", 350)

e10 = EliminationType.find_or_create_by_name("Poças d’água na rua")
m22 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e10, "Elimine a água com rodo ou vassoura", 50)

e11 = EliminationType.find_or_create_by_name("Ralos")
m23 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e11, "Jogue água sanitária ou desinfetante semanalmente.", 50)
m24 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e11, "Elimine entupimento", 50)
m25 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e11, "Vede ralos não utilizados", 50)

e12 = EliminationType.find_or_create_by_name("Plantas aquáticas em vaso de água")
m26 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e12, "Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água.", 50)
m27 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e12, "Retire a água acumulada nas folhas", 50)
m28 = EliminationMethod.find_or_create_by_elimination_type_id_and_method_and_points(e12, "Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água.", 50)


puts "\n" * 3
puts "[ok] Done seeding elimination types and methods"
puts "-" * 80
