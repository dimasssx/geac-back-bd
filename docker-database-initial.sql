CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE categories
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE locations
(
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    street          VARCHAR(150) NOT NULL,
    number          VARCHAR(20),
    neighborhood    VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(2)   NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,
    reference_point TEXT,
    capacity        INTEGER      NOT NULL
);

CREATE TABLE users
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type     VARCHAR(20),
    created_at    TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE requirements (
                              id SERIAL PRIMARY KEY,
                              description VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE tags
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE events
(
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizer_id   UUID      NOT NULL REFERENCES users (id),
    category_id    INTEGER      NOT NULL REFERENCES categories (id),
    location_id    INTEGER REFERENCES locations (id),

    title          VARCHAR(200) NOT NULL,
    description    TEXT         NOT NULL,
    online_link    VARCHAR(255),

    start_time     TIMESTAMP    NOT NULL,
    end_time       TIMESTAMP    NOT NULL,
    workload_hours INTEGER      NOT NULL,
    max_capacity   INTEGER      NOT NULL,
    requirement_id INTEGER NOT NULL REFERENCES requirements(id),

    status         VARCHAR(20),
    created_at     TIMESTAMP        DEFAULT NOW()
);

-- SÓ AGORA CRIAMOS EVENT_TAGS
CREATE TABLE event_tags
(
    event_id UUID    NOT NULL REFERENCES events (id),
    tag_id   INTEGER NOT NULL REFERENCES tags (id),
    PRIMARY KEY (event_id, tag_id)
);

-- ==========================================
-- DADOS INICIAIS (SEED) PARA TESTES DE EVENTO
-- ==========================================

INSERT INTO public.users (id, full_name, email, password_hash, user_type, created_at) VALUES
                                                                                          ('be89dede-00f2-48eb-880b-c9b728ce5bfc', 'student1', 'student1@test.com', '$2a$10$kXz14cSQ4CuM8ev7MKWtQu1/4Ny7v/ic5xuQxgwZzh.x9ZHLuxOM2', 'STUDENT', NOW()),
                                                                                          ('b82120cf-41a7-406a-b52d-259cdbef3041', 'student2', 'student2@test.com', '$2a$10$.bW0KlZDt.tkGrj6xxTgL./OoUtYrmaq3re.ABGjN7u4pHnnl.k3G', 'STUDENT', NOW()),
                                                                                          ('5c0a92a1-b445-4e4b-807c-6fbca67b9092', 'student3', 'student3@test.com', '$2a$10$TTE/WAR4tTdILrWFdC7aDOT1lJzwHpNVY8MYBiHkw1q6Ki3oQFy7G', 'STUDENT', NOW()),
                                                                                          ('9be3d05c-7638-4f78-814a-ce4c21463262', 'student4', 'student4@test.com', '$2a$10$6R/amLD0hO1oMDMyCSiA4.jCJgcKuPgYFv9wxpmLt9d0Fx/YXyR9q', 'STUDENT', NOW()),
                                                                                          ('286c2d18-9814-4d88-a55d-14bacaefcf49', 'student5', 'student5@test.com', '$2a$10$kWOVCbnEdBKwoirx8IvxxuBC1r5TS8O8/ekLd1JkAKlVvW6rDLajy', 'STUDENT', NOW()),
                                                                                          ('073b9076-2317-4511-a9c3-535654e75363', 'professor1', 'professor1@test.com', '$2a$10$UAH/nCUUYJ6Cklr79GLUVuY91SBHZh.JmyP/Id6NdnTBvhG6m5Vma', 'PROFESSOR', NOW()),
                                                                                          ('be4999bf-6d31-4414-a0a6-ae61d53a6387', 'professor2', 'professor2@test.com', '$2a$10$MOljMoo4PYuoz4yzBJK8K.tW/2iBtWFcFUkZv8d5RuGfIMikJITDu', 'PROFESSOR', NOW()),
                                                                                          ('54307ac7-8117-42c3-abc2-a74b112979c3', 'professor3', 'professor3@test.com', '$2a$10$q0K2zMKAZ2w0XRTektFvcO1TiQ1IKFTSp.biRbH6W9.uL5IcFDrgG', 'PROFESSOR', NOW());


INSERT INTO categories (name, description)
VALUES
    ('hackathon', ''),
    ('palestra', ''),
    ('seminario', ''),
    ('cultural', ''),
    ('feira', ''),
    ('workshop', ''),
    ('livre', ''),
    ('conferencia', ''),
    ('festival', ''),
    ('outro', '');

INSERT INTO public.locations (name, street, number, neighborhood, city, state, zip_code, reference_point, capacity)
VALUES
    ('Laboratório de Informática 01', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio Principal', 40),
    ('Sala de Aula 101', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco A', 50),
    ('Sala de Aula 102', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco A', 50),
    ('Sala de Aula 103', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco A', 50),
    ('Sala de Aula 104', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco A', 50),
    ('Sala de Aula 201', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco B', 60),
    ('Sala de Aula 202', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco B', 60),
    ('Laboratório de Química', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio de Ciências', 30),
    ( 'Laboratório de Física', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio de Ciências', 30),
    ( 'Laboratório de Biologia', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio de Ciências', 35),
    ( 'Auditório Principal', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Térreo', 250),
    ( 'Mini Auditório', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Bloco C', 80),
    ( 'Biblioteca Central', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio Anexo', 150),
    ( 'Sala de Estudos 01', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Dentro da Biblioteca', 20),
    ( 'Sala de Estudos 02', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Dentro da Biblioteca', 20),
    ( 'Sala de Reuniões Coordenação', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio Administrativo', 15),
    ( 'Quadra Poliesportiva', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Área Externa', 500),
    ( 'Espaço Maker', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio de Inovação', 45),
    ( 'Estúdio de Gravação', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Prédio de Comunicação', 10),
    ( 'Laboratório de Redes', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 1', 40),
    ( 'Laboratório de Hardware', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 1', 35),
    ( 'Sala de Aula 301', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 2', 55),
    ( 'Sala de Aula 302', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 2', 55),
    ( 'Sala de Aula 303', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 2', 55),
    ( 'Auditório Paulo Freire', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Térreo', 300),
    ( 'Sala de Videoconferência', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 1', 25),
    ( 'Laboratório de Robótica', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 3', 30),
    ( 'Sala de Metodologias Ativas 1', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 3', 40),
    ( 'Sala de Metodologias Ativas 2', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 3', 40),
    ( 'Biblioteca Setorial', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco 4', 100),
    ( 'Laboratório de Enfermagem', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco Saúde', 30),
    ( 'Laboratório de Anatomia', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco Saúde', 40),
    ( 'Clínica Escola', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife - Bloco Saúde', 50),
    ( 'Sala de Aula 401', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco A', 60),
    ( 'Sala de Aula 402', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco A', 60),
    ( 'Sala de Aula 403', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco A', 60),
    ( 'Laboratório de Design', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco B', 35),
    ( 'Laboratório de Moda', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco B', 30),
    ( 'Ateliê de Costura', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco B', 25),
    ( 'Sala de Desenho', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco B', 40),
    ( 'Auditório Ariano Suassuna', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Central', 200),
    ( 'Laboratório de Informática 03', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco C', 40),
    ( 'Laboratório de Informática 04', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco C', 40),
    ( 'Sala de Reuniões Professores', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Administrativo', 20),
    ( 'Espaço de Convivência', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Externo', 150),
    ( 'Laboratório de Fotografia', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco D', 20),
    ( 'Estúdio de Áudio', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco D', 15),
    ( 'Sala de Defesas', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Bloco Pós', 35),
    ( 'Laboratório Maker Avançado', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000', 'Campus Caruaru - Inovação', 40);

INSERT INTO requirements (description)
VALUES
    ('Trazer notebook'),
    ('$5 para corpo docente/funcionários'),
    ('Aberto a todos os alunos e corpo docente'),
    ('Aberto a todos os estudantes'),
    ('Conhecimento básico de marketing é útil'),
    ('Entrada gratuita'),
    ('Estudantes: grátis'),
    ('Inscrição necessária para vales-alimentação'),
    ('Recomendado entendimento básico de criptomoedas'),
    ('Recomendado para estudantes de Ciências Ambientais e áreas relacionadas'),
    ('Traje esporte fino recomendado'),
    ('Trazer currículos impressos');

INSERT INTO tags (name)
VALUES
    ('apoio'),
    ('artes'),
    ('bem-estar'),
    ('blockchain'),
    ('carreira'),
    ('ciência'),
    ('clima'),
    ('criptomoedas'),
    ('cultura'),
    ('digital'),
    ('diversidade'),
    ('empregos'),
    ('estudantes'),
    ('festival'),
    ('finanças'),
    ('ia'),
    ('inovação'),
    ('internacional'),
    ('marketing'),
    ('meio ambiente'),
    ('música'),
    ('negócios'),
    ('networking'),
    ('performance'),
    ('rock'),
    ('saúde mental'),
    ('sustentabilidade'),
    ('tecnologia'),
    ('workshop');


insert into public.events (id, organizer_id, category_id, location_id, title, description, online_link, start_time, end_time, workload_hours, max_capacity, requirement_id, status, created_at)
values
    ('e153c21a-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 2, 1, 'Inteligência Artificial e o Futuro do Trabalho', 'Junte-se a nós para uma palestra esclarecedora sobre como a IA está transformando o local de trabalho e o que isso significa para os futuros profissionais. O Dr. Fulano de Tal discutirá as tendências atuais, considerações éticas e oportunidades de carreira em IA.', 'https://example.com/ia-futuro-trabalho', '2026-02-20 14:00:00.000000', '2026-02-20 16:00:00.000000', 2, 200, 3, 'upcoming', NOW()),
    (
        'e2222222-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 4, 18,
        'Festival Cultural Internacional 2026',
        'Experimente uma celebração da diversidade com apresentações, comida e exposições de mais de 30 países. Este festival anual reúne nossa comunidade internacional para compartilhar tradições, música, dança e culinária.',
        NULL, '2026-03-15 10:00:00.000000', '2026-03-15 18:00:00.000000', 8, 1000, 6, 'upcoming', NOW()
    ),
    (
        'e3333333-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 3, 26,
        'Mudanças Climáticas: Ciência e Ação',
        'Uma série abrangente de seminários com os principais cientistas climáticos e ativistas ambientais. Aprenda sobre as pesquisas mais recentes, iniciativas políticas e passos práticos para um futuro sustentável.',
        'https://example.com/mudancas-climaticas', '2026-02-28 09:00:00.000000', '2026-02-28 13:00:00.000000', 4, 100, 10, 'upcoming', NOW()
    ),
    (
        'e4444444-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 5, 42,
        'Feira de Carreiras 2026: Tecnologia e Inovação',
        'Encontre-se com representantes de mais de 50 empresas líderes em tecnologia. Faça networking com recrutadores, envie seu currículo e saiba mais sobre estágios e oportunidades de tempo integral na indústria de tecnologia.',
        'https://example.com/feira-carreiras', '2026-03-05 11:00:00.000000', '2026-03-05 17:00:00.000000', 6, 500, 12, 'upcoming', NOW()
    ),
    (
        'e5555555-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 6, 13,
        'Workshop de Estratégias de Marketing Digital',
        'Workshop prático cobrindo marketing em mídias sociais, SEO, criação de conteúdo e análise de dados. Perfeito para estudantes interessados em carreiras de marketing ou empreendedores que desejam aumentar sua presença online.',
        'https://example.com/workshop-marketing', '2026-02-25 15:00:00.000000', '2026-02-25 18:00:00.000000', 3, 50, 1, 'upcoming', NOW()
    ),
    (
        'e6666666-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 3, 17,
        'Seminário de Saúde Mental e Bem-Estar',
        'Uma discussão importante sobre saúde mental estudantil, técnicas de gerenciamento de estresse e recursos disponíveis no campus. Aprenda com profissionais de aconselhamento e ouça representantes estudantis.',
        'https://example.com/saude-mental', '2026-02-18 16:00:00.000000', '2026-02-18 18:00:00.000000', 2, 80, 4, 'upcoming', NOW()
    ),
    (
        'e7777777-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 4, 12,
        'Noite de Rock na Universidade',
        'Desfrute de uma noite de música rock ao vivo apresentada pelo Conjunto de Pseudo Músicos da Universidade e artistas convidados especiais. Uma mistura perfeita de talento estudantil e musicalidade profissional.',
        'https://example.com/noite-rock', '2026-03-10 19:00:00.000000', '2026-03-10 21:30:00.000000', 2.5, 250, 7, 'cancelled', NOW()
    ),
    (
        'e8888888-d628-46ef-b838-b66d4758b966', '073b9076-2317-4511-a9c3-535654e75363', 8, 19,
        'Conferência sobre Blockchain e Criptomoedas',
        'Explore o mundo da tecnologia blockchain, mercados de criptomoedas e finanças descentralizadas. Especialistas da indústria discutirão aplicações do mundo real e tendências futuras.',
        'https://example.com/conferencia-blockchain', '2026-03-22 10:00:00.000000', '2026-03-22 16:00:00.000000', 6, 150, 9, 'upcoming', NOW()
    );

INSERT INTO public.event_tags (event_id, tag_id)
VALUES
    -- Evento 1 (Inteligência Artificial)
    ('e153c21a-d628-46ef-b838-b66d4758b966', 5),
    ('e153c21a-d628-46ef-b838-b66d4758b966', 16),
    ('e153c21a-d628-46ef-b838-b66d4758b966', 17),
    ('e153c21a-d628-46ef-b838-b66d4758b966', 28),

    -- Evento 2 (Festival Cultural)
    ('e2222222-d628-46ef-b838-b66d4758b966', 9),
    ('e2222222-d628-46ef-b838-b66d4758b966', 11),
    ('e2222222-d628-46ef-b838-b66d4758b966', 14),
    ('e2222222-d628-46ef-b838-b66d4758b966', 18),

    -- Evento 3 (Mudanças Climáticas)
    ('e3333333-d628-46ef-b838-b66d4758b966', 6),
    ('e3333333-d628-46ef-b838-b66d4758b966', 7),
    ('e3333333-d628-46ef-b838-b66d4758b966', 20),
    ('e3333333-d628-46ef-b838-b66d4758b966', 27),

    -- Evento 4 (Feira de Carreiras)
    ('e4444444-d628-46ef-b838-b66d4758b966', 5),
    ('e4444444-d628-46ef-b838-b66d4758b966', 12),
    ('e4444444-d628-46ef-b838-b66d4758b966', 23),
    ('e4444444-d628-46ef-b838-b66d4758b966', 28),

    -- Evento 5 (Workshop de Marketing)
    ('e5555555-d628-46ef-b838-b66d4758b966', 10),
    ('e5555555-d628-46ef-b838-b66d4758b966', 19),
    ('e5555555-d628-46ef-b838-b66d4758b966', 22),
    ('e5555555-d628-46ef-b838-b66d4758b966', 29),

    -- Evento 6 (Seminário de Saúde Mental)
    ('e6666666-d628-46ef-b838-b66d4758b966', 1),
    ('e6666666-d628-46ef-b838-b66d4758b966', 3),
    ('e6666666-d628-46ef-b838-b66d4758b966', 13),
    ('e6666666-d628-46ef-b838-b66d4758b966', 26),

    -- Evento 7 (Noite de Rock)
    ('e7777777-d628-46ef-b838-b66d4758b966', 2),
    ('e7777777-d628-46ef-b838-b66d4758b966', 21),
    ('e7777777-d628-46ef-b838-b66d4758b966', 24),
    ('e7777777-d628-46ef-b838-b66d4758b966', 25),

    -- Evento 8 (Conferência sobre Blockchain)
    ('e8888888-d628-46ef-b838-b66d4758b966', 4),
    ('e8888888-d628-46ef-b838-b66d4758b966', 8),
    ('e8888888-d628-46ef-b838-b66d4758b966', 15),
    ('e8888888-d628-46ef-b838-b66d4758b966', 28);