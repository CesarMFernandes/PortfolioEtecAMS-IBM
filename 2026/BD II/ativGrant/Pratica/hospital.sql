CREATE DATABASE hospital_db;
USE hospital_db;

-- Tabela com dados públicos de agendamento
CREATE TABLE agendamentos (
    id_agenda INT AUTO_INCREMENT PRIMARY KEY,
    paciente_nome VARCHAR(100),
    data_consulta DATE,
    hora_consulta TIME,
    medico_responsavel VARCHAR(100)
);

-- Tabela com dados sensíveis de prontuário
CREATE TABLE prontuarios (
    id_prontuario INT AUTO_INCREMENT PRIMARY KEY,
    paciente_nome VARCHAR(100),
    diagnostico TEXT,
    medicacao_prescrita TEXT,
    historico_familiar TEXT
);

-- Inserindo dados de teste
INSERT INTO agendamentos (paciente_nome, data_consulta, hora_consulta, medico_responsavel) VALUES
('Carlos Silva', '2026-05-10', '08:00', 'Dr. Arnaldo'),
('Maria Souza', '2026-05-10', '09:00', 'Dra. Beatriz');

INSERT INTO prontuarios (paciente_nome, diagnostico, medicacao_prescrita) VALUES
('Carlos Silva', 'Hipertensão Estágio 1', 'Enalapril 20mg'),
('Maria Souza', 'Enxaqueca Crônica', 'Sumatriptana 50mg');

select * from agendamentos;
select * from prontuarios;

create user 'recepcao_central'@'localhost' identified by 'SenhaRec#123';
create user 'medico_geral'@'localhost' identified by 'Med@Secure!2026';

grant select on hospital_db.agendamentos to 'recepcao_central'@'localhost';
grant insert on hospital_db.agendamentos to 'recepcao_central'@'localhost';

grant all privileges on hospital_db.agendamentos to 'medico_geral'@'localhost';
grant all privileges on hospital_db.prontuarios to 'medico_geral'@'localhost';

select * from mysql.user;

revoke delete on hospital_db.prontuarios from 'medico_geral'@'localhost';

show grants for 'recepcao_central'@'localhost';
show grants for 'medico_geral'@'localhost';

drop database hospital_db;