CREATE TABLE instutor(
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    salario DECIMAL(10, 2)
);

INSERT INTO instutor (nome, salario) VALUES ('Luís Felipe de Cristo', 959);
INSERT INTO instutor (nome, salario) VALUES ('Khyria', 2000);
INSERT INTO instutor (nome, salario) VALUES ('Nicolas Cioczek', 1500);
INSERT INTO instutor (nome, salario) VALUES ('MeRyon Lamborghini', 1300);
INSERT INTO instutor (nome, salario) VALUES ('LyOne Porsche', 960);

CREATE FUNCTION double_salario (instutor) RETURNS DECIMAL AS $$
    SELECT $1.salario * 2 AS dobro;
    $$ LANGUAGE SQL;

SELECT nome, double_salario(instutor.*) FROM instutor;

CREATE OR REPLACE FUNCTION instrutor_false() RETURNS instutor AS $$
    SELECT 23 AS id, 'VOID' AS nome, 900::DECIMAL AS salario;
    $$ LANGUAGE SQL;

SELECT id, salario FROM instrutor_false();

DROP FUNCTION instrutores_tops;
CREATE FUNCTION instrutores_tops (valor_salario DECIMAL) RETURNS SETOF instutor AS $$
    BEGIN
    RETURN QUERY SELECT * FROM instutor WHERE salario > valor_salario;
    END;
    $$ LANGUAGE PLPGSQL;

SELECT * FROM instrutores_tops(959);

DROP FUNCTION salario_ok;
CREATE FUNCTION salario_ok (id_instutor INTEGER) RETURNS VARCHAR AS $$
    DECLARE
        instutor instutor;
    BEGIN
        SELECT * FROM instutor WHERE id = id_instutor INTO instutor;
        /*IF instutor.salario > 1500 THEN
            RETURN 'Salário esta ok, mas pode aumentar!';
        ELSEIF instutor.salario = 1500 THEN
            RETURN 'Salário precisa aumentar!';
            ELSE
            RETURN 'Estágiario é foda :(';
        END IF;*/
        CASE instutor.salario
            WHEN 2000 THEN
             RETURN 'Salário esta ok, mas pode aumentar!';
             WHEN 1500 THEN
             RETURN 'Salário precisa aumentar!';
             ELSE
            RETURN 'Estágiario é foda :(';
        END CASE;
    END;
$$ LANGUAGE PLPGSQL;

SELECT nome, salario_ok(instutor.id) FROM instutor;

DROP FUNCTION multiplicationTable;
CREATE FUNCTION multiplicationTable (numero INTEGER) RETURNS SETOF VARCHAR AS $$
        BEGIN
            FOR multiplicador IN 1..10 LOOP
                RETURN NEXT numero || ' x ' || multiplicador || ' = ' || numero * multiplicador;
            END LOOP;
        END;
    $$ LANGUAGE PLPGSQL;

SELECT multiplicationTable(10);

DROP FUNCTION instrutor_with_salario;
CREATE FUNCTION instrutor_with_salario(OUT nome VARCHAR, OUT salario_ok VARCHAR) RETURNS SETOF record AS $$
    DECLARE
        instutor instutor;
    BEGIN
        FOR instutor IN SELECT * FROM instutor LOOP
            nome := instutor.nome;
            salario_ok = salario_ok(instutor.id);

            RETURN NEXT;
            END LOOP;
    END;
    $$ LANGUAGE PLPGSQL;

SELECT * FROM instrutor_with_salario();

CREATE TABLE aluno (
    id SERIAL PRIMARY KEY,
	primeiro_nome VARCHAR(255) NOT NULL,
	ultimo_nome VARCHAR(255) NOT NULL,
	data_nascimento DATE NOT NULL
);

CREATE TABLE categoria (
    id SERIAL PRIMARY KEY,
	nome VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE curso (
    id SERIAL PRIMARY KEY,
	nome VARCHAR(255) NOT NULL,
	categoria_id INTEGER NOT NULL REFERENCES categoria(id)
);

CREATE TABLE aluno_curso (
	aluno_id INTEGER NOT NULL REFERENCES aluno(id),
	curso_id INTEGER NOT NULL REFERENCES curso(id),
	PRIMARY KEY (aluno_id, curso_id)
);

CREATE FUNCTION cria_curso(nome_curso VARCHAR, nome_categoria VARCHAR) RETURNS void AS $$
    DECLARE
        id_categoria INTEGER;
    BEGIN
        SELECT id INTO id_categoria FROM categoria WHERE nome = nome_categoria;

        IF NOT FOUND THEN
            INSERT INTO categoria (nome) VALUES (nome_categoria) RETURNING id INTO id_categoria;
        END IF;

        INSERT INTO curso (nome, categoria_id) VALUES (nome_curso, id_categoria);
    END;

$$ LANGUAGE PLPGSQL;

SELECT cria_curso('SvelteKit', 'Front-End');

SELECT * FROM curso;

CREATE TABLE log(
    id SERIAL PRIMARY KEY,
    info VARCHAR(255),
    moment_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION cria_instrutores(nome_instrutor VARCHAR, salario_instrutor DECIMAL) RETURNS void AS $$
    DECLARE
        id_instrutor_inserido INTEGER;
        media_salarial DECIMAL;
        instrutores_recebem_menos INTEGER DEFAULT 0;
        total_instrutores INTEGER DEFAULT 0;
        salario DECIMAL;
        percentual DECIMAL;
    BEGIN
        INSERT INTO instutor (nome, salario) VALUES (nome_instrutor, salario_instrutor) RETURNING id INTO id_instrutor_inserido;

        SELECT AVG(instutor.salario) INTO media_salarial FROM instutor WHERE id <> id_instrutor_inserido;

        IF salario_instrutor > media_salarial THEN
            INSERT INTO log (info) VALUES (nome_instrutor || ' recebe acima da média! ');
        END IF;

        FOR salario IN SELECT instutor.salario FROM instutor WHERE id <> id_instrutor_inserido LOOP
            total_instrutores := total_instrutores + 1;

            IF salario_instrutor > salario THEN
                instrutores_recebem_menos := instrutores_recebem_menos + 1;
            END IF;
        END LOOP;

        percentual = instrutores_recebem_menos::DECIMAL / total_instrutores::DECIMAL * 100;

        INSERT INTO log (info)
        VALUES (nome_instrutor || 'recebe mais do que ' || percentual || '% da grade de instrutores');
        END;
    $$ LANGUAGE PLPGSQL;

SELECT * FROM instutor;
SELECT cria_instrutores('Void', 3000);
SELECT * FROM log;
